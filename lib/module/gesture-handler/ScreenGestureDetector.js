import React, { useEffect } from 'react';
import { Dimensions, Platform, findNodeHandle } from 'react-native';
import { GestureDetector, Gesture } from 'react-native-gesture-handler';
import { useSharedValue, measure, startScreenTransition, finishScreenTransition, makeMutable, runOnUI } from 'react-native-reanimated';
import { getShadowNodeWrapperAndTagFromRef, isFabric } from './fabricUtils';
import { RNScreensTurboModule } from './RNScreensTurboModule';
import { DefaultEvent, DefaultScreenDimensions } from './defaults';
import { checkBoundaries, checkIfTransitionCancelled, getAnimationForTransition } from './constraints';
// The detector is disabled to work around issue with pressables
// losing focus. See https://github.com/software-mansion/react-native-screens/pull/2819
const EmptyGestureHandler = Gesture.Fling().enabled(false);
const ScreenGestureDetector = ({
  children,
  gestureDetectorBridge,
  goBackGesture,
  screenEdgeGesture,
  transitionAnimation: customTransitionAnimation,
  screensRefs,
  currentScreenId
}) => {
  const sharedEvent = useSharedValue(DefaultEvent);
  const startingGesturePosition = useSharedValue(DefaultEvent);
  const canPerformUpdates = makeMutable(false);
  const transitionAnimation = getAnimationForTransition(goBackGesture, customTransitionAnimation);
  const screenTransitionConfig = makeMutable({
    stackTag: -1,
    belowTopScreenId: -1,
    topScreenId: -1,
    sharedEvent,
    startingGesturePosition,
    screenTransition: transitionAnimation,
    isTransitionCanceled: false,
    goBackGesture: goBackGesture ?? 'swipeRight',
    screenDimensions: DefaultScreenDimensions,
    onFinishAnimation: () => {
      'worklet';
    }
  });
  const stackTag = makeMutable(-1);
  const screenTagToNodeWrapperUI = makeMutable({});
  const IS_FABRIC = isFabric();
  gestureDetectorBridge.current.stackUseEffectCallback = stackRef => {
    if (!goBackGesture) {
      return;
    }
    stackTag.value = findNodeHandle(stackRef.current);
    if (Platform.OS === 'ios') {
      runOnUI(() => {
        RNScreensTurboModule.disableSwipeBackForTopScreen(stackTag.value);
      })();
    }
  };
  useEffect(() => {
    if (!IS_FABRIC || !goBackGesture || screensRefs === undefined) {
      return;
    }
    const screenTagToNodeWrapper = {};
    for (const key in screensRefs.current) {
      const screenRef = screensRefs.current[key];
      const screenData = getShadowNodeWrapperAndTagFromRef(screenRef.current);
      if (screenData.tag && screenData.shadowNodeWrapper) {
        screenTagToNodeWrapper[screenData.tag] = screenData.shadowNodeWrapper;
      } else {
        console.warn('[RNScreens] Failed to find tag for screen.');
      }
    }
    screenTagToNodeWrapperUI.value = screenTagToNodeWrapper;
  }, [currentScreenId, goBackGesture]);
  function computeProgress(event) {
    'worklet';

    let progress = 0;
    const screenDimensions = screenTransitionConfig.value.screenDimensions;
    const startingPosition = startingGesturePosition.value;
    if (goBackGesture === 'swipeRight') {
      progress = event.translationX / (screenDimensions.width - startingPosition.absoluteX);
    } else if (goBackGesture === 'swipeLeft') {
      progress = -1 * event.translationX / startingPosition.absoluteX;
    } else if (goBackGesture === 'swipeDown') {
      progress = -1 * event.translationY / (screenDimensions.height - startingPosition.absoluteY);
    } else if (goBackGesture === 'swipeUp') {
      progress = event.translationY / startingPosition.absoluteY;
    } else if (goBackGesture === 'horizontalSwipe') {
      progress = Math.abs(event.translationX / screenDimensions.width / 2);
    } else if (goBackGesture === 'verticalSwipe') {
      progress = Math.abs(event.translationY / screenDimensions.height / 2);
    } else if (goBackGesture === 'twoDimensionalSwipe') {
      const progressX = Math.abs(event.translationX / screenDimensions.width / 2);
      const progressY = Math.abs(event.translationY / screenDimensions.height / 2);
      progress = Math.max(progressX, progressY);
    }
    return progress;
  }
  function onStart(event) {
    'worklet';

    sharedEvent.value = event;
    const transitionConfig = screenTransitionConfig.value;
    const transitionData = RNScreensTurboModule.startTransition(stackTag.value);
    if (transitionData.canStartTransition === false) {
      canPerformUpdates.value = false;
      return;
    }
    if (IS_FABRIC) {
      transitionConfig.topScreenId = screenTagToNodeWrapperUI.value[transitionData.topScreenTag];
      transitionConfig.belowTopScreenId = screenTagToNodeWrapperUI.value[transitionData.belowTopScreenTag];
    } else {
      transitionConfig.topScreenId = transitionData.topScreenTag;
      transitionConfig.belowTopScreenId = transitionData.belowTopScreenTag;
    }
    transitionConfig.stackTag = stackTag.value;
    startingGesturePosition.value = event;
    const animatedRefMock = () => {
      return screenTransitionConfig.value.topScreenId;
    };
    const screenSize = measure(animatedRefMock);
    if (screenSize == null) {
      throw new Error('[RNScreens] Failed to measure screen.');
    }
    if (screenSize == null) {
      canPerformUpdates.value = false;
      RNScreensTurboModule.finishTransition(stackTag.value, true);
      return;
    }
    transitionConfig.screenDimensions = screenSize;
    // Gesture Handler added `pointerType` to event payload back in 2.16.0,
    // see: https://github.com/software-mansion/react-native-gesture-handler/pull/2760
    // and this causes type errors here. Proper solution would be to patch parameter types
    // of this function in reanimated. This should not cause runtime errors as the payload
    // has correct shape, only the types are incorrect.
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    startScreenTransition(transitionConfig);
    canPerformUpdates.value = true;
  }
  function onUpdate(event) {
    'worklet';

    if (!canPerformUpdates.value) {
      return;
    }
    checkBoundaries(goBackGesture, event);
    const progress = computeProgress(event);
    sharedEvent.value = event;
    const stackTag = screenTransitionConfig.value.stackTag;
    RNScreensTurboModule.updateTransition(stackTag, progress);
  }
  function onEnd(event) {
    'worklet';

    if (!canPerformUpdates.value) {
      return;
    }
    const velocityFactor = 0.3;
    const screenSize = screenTransitionConfig.value.screenDimensions;
    const distanceX = event.translationX + Math.min(event.velocityX * velocityFactor, 100);
    const distanceY = event.translationY + Math.min(event.velocityY * velocityFactor, 100);
    const requiredXDistance = screenSize.width / 2;
    const requiredYDistance = screenSize.height / 2;
    const isTransitionCanceled = checkIfTransitionCancelled(goBackGesture, distanceX, requiredXDistance, distanceY, requiredYDistance);
    const stackTag = screenTransitionConfig.value.stackTag;
    screenTransitionConfig.value.onFinishAnimation = () => {
      RNScreensTurboModule.finishTransition(stackTag, isTransitionCanceled);
    };
    screenTransitionConfig.value.isTransitionCanceled = isTransitionCanceled;
    // Gesture Handler added `pointerType` to event payload back in 2.16.0,
    // see: https://github.com/software-mansion/react-native-gesture-handler/pull/2760
    // and this causes type errors here. Proper solution would be to patch parameter types
    // of this function in reanimated. This should not cause runtime errors as the payload
    // has correct shape, only the types are incorrect.
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    finishScreenTransition(screenTransitionConfig.value);
  }
  let panGesture = Gesture.Pan().onStart(onStart).onUpdate(onUpdate).onEnd(onEnd);
  if (screenEdgeGesture) {
    const HIT_SLOP_SIZE = 50;
    const ACTIVATION_DISTANCE = 30;
    if (goBackGesture === 'swipeRight') {
      panGesture = panGesture.activeOffsetX(ACTIVATION_DISTANCE).hitSlop({
        left: 0,
        top: 0,
        width: HIT_SLOP_SIZE
      });
    } else if (goBackGesture === 'swipeLeft') {
      panGesture = panGesture.activeOffsetX(-ACTIVATION_DISTANCE).hitSlop({
        right: 0,
        top: 0,
        width: HIT_SLOP_SIZE
      });
    } else if (goBackGesture === 'swipeDown') {
      panGesture = panGesture.activeOffsetY(ACTIVATION_DISTANCE).hitSlop({
        top: 0,
        height: Dimensions.get('window').height * 0.2
      });
      // workaround, because we don't have access to header height
    } else if (goBackGesture === 'swipeUp') {
      panGesture = panGesture.activeOffsetY(-ACTIVATION_DISTANCE).hitSlop({
        bottom: 0,
        height: HIT_SLOP_SIZE
      });
    }
  }
  return /*#__PURE__*/React.createElement(GestureDetector, {
    gesture: goBackGesture ? panGesture : EmptyGestureHandler
  }, children);
};
export default ScreenGestureDetector;
//# sourceMappingURL=ScreenGestureDetector.js.map