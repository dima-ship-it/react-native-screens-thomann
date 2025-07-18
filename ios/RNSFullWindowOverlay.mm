#import <UIKit/UIKit.h>

#import "RNSDefines.h"
#import "RNSFullWindowOverlay.h"

#ifdef RCT_NEW_ARCH_ENABLED
#import <React/RCTConversions.h>
#import <React/RCTFabricComponentsPlugins.h>
#import <React/RCTSurfaceTouchHandler.h>
#import <react/renderer/components/rnscreens/ComponentDescriptors.h>
#import <react/renderer/components/rnscreens/Props.h>
#import <react/renderer/components/rnscreens/RCTComponentViewHelpers.h>
#import <rnscreens/RNSFullWindowOverlayComponentDescriptor.h>
#else
#import <React/RCTTouchHandler.h>
#endif // RCT_NEW_ARCH_ENABLED

@implementation RNSFullWindowOverlayContainer

- (instancetype)initWithFrame:(CGRect)frame
     accessibilityViewIsModal:(BOOL)accessibilityViewIsModal
         accessibilityEnabled:(BOOL)accessibilityEnabled
{
  if (self = [super initWithFrame:frame]) {
    self.accessibilityViewIsModal = accessibilityViewIsModal;
    // Don't set accessibilityEnabled here!
    // Just leave it at its default (true) — RN will call the setter shortly after.
  }
  return self;
}

- (void)setAccessibilityEnabled:(BOOL)enabled
{
  _accessibilityEnabled = enabled;
  [self updateAccessibility];
}

- (void)updateAccessibility
{
  if (self.accessibilityEnabled) {
    self.accessibilityElementsHidden = NO;
    self.isAccessibilityElement = NO;
  } else {
    self.accessibilityElementsHidden = YES;
    self.isAccessibilityElement = NO;
  }
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
  for (UIView *view in [self subviews]) {
    if (view.userInteractionEnabled && [view pointInside:[self convertPoint:point toView:view] withEvent:event]) {
      return YES;
    }
  }
  return NO;
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  BOOL canReceiveTouchEvents = ([self isUserInteractionEnabled] && ![self isHidden]);
  if (!canReceiveTouchEvents) {
    return nil;
  }

  // `hitSubview` is the topmost subview which was hit. The hit point can
  // be outside the bounds of `view` (e.g., if -clipsToBounds is NO).
  UIView *hitSubview = nil;
  BOOL isPointInside = [self pointInside:point withEvent:event];
  if (![self clipsToBounds] || isPointInside) {
    // Take z-index into account when calculating the touch target.
    NSArray<UIView *> *sortedSubviews = [self reactZIndexSortedSubviews];

    // The default behaviour of UIKit is that if a view does not contain a point,
    // then no subviews will be returned from hit testing, even if they contain
    // the hit point. By doing hit testing directly on the subviews, we bypass
    // the strict containment policy (i.e., UIKit guarantees that every ancestor
    // of the hit view will return YES from -pointInside:withEvent:). See:
    //  - https://developer.apple.com/library/ios/qa/qa2013/qa1812.html
    for (UIView *subview in [sortedSubviews reverseObjectEnumerator]) {
      CGPoint convertedPoint = [subview convertPoint:point fromView:self];
      hitSubview = [subview hitTest:convertedPoint withEvent:event];
      if (hitSubview != nil) {
        break;
      }
    }
  }
  return hitSubview;
}

@end

@implementation RNSFullWindowOverlay {
  __weak RCTBridge *_bridge;
  RNSFullWindowOverlayContainer *_container;
  CGRect _reactFrame;
#ifdef RCT_NEW_ARCH_ENABLED
  RCTSurfaceTouchHandler *_touchHandler;
#else
  RCTTouchHandler *_touchHandler;
#endif // RCT_NEW_ARCH_ENABLED
}

// Needed because of this: https://github.com/facebook/react-native/pull/37274
+ (void)load
{
  [super load];
}

#ifdef RCT_NEW_ARCH_ENABLED
- (instancetype)init
{
  if (self = [super init]) {
    static const auto defaultProps = std::make_shared<const react::RNSFullWindowOverlayProps>();
    _props = defaultProps;
    [self initCommonProps];
  }
  return self;
}
#else
- (instancetype)initWithBridge:(RCTBridge *)bridge
{
  if (self = [super init]) {
    _bridge = bridge;
    [self initCommonProps];
  }

  return self;
}
#endif // RCT_NEW_ARCH_ENABLED

- (void)initCommonProps
{
  // Default value used by container.
  _accessibilityContainerViewIsModal = YES;
  _accessibilityEnabled = YES;
  _reactFrame = CGRectNull;
  _container = self.container;
  [self show];
}

- (void)setAccessibilityContainerViewIsModal:(BOOL)accessibilityContainerViewIsModal
{
  _accessibilityContainerViewIsModal = accessibilityContainerViewIsModal;
  self.container.accessibilityViewIsModal = accessibilityContainerViewIsModal;
}

- (void)setAccessibilityEnabled:(BOOL)accessibilityEnabled
{
  _accessibilityEnabled = accessibilityEnabled;
  self.container.accessibilityEnabled = accessibilityEnabled;
}

- (void)addSubview:(UIView *)view
{
  [_container addSubview:view];
}

- (RNSFullWindowOverlayContainer *)container
{
  if (_container == nil) {
    _container = [[RNSFullWindowOverlayContainer alloc] initWithFrame:_reactFrame
                                             accessibilityViewIsModal:_accessibilityContainerViewIsModal
                                                 accessibilityEnabled:_accessibilityEnabled];
  }

  return _container;
}

- (void)show
{
  UIWindow *window = RCTKeyWindow();
  [window addSubview:_container];
}

- (void)didMoveToSuperview
{
  if (self.superview == nil) {
    if (_container != nil) {
      [_container removeFromSuperview];
      [_touchHandler detachFromView:_container];
    }
  } else {
    if (_container != nil) {
      UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, _container);
    }
    if (_touchHandler == nil) {
#ifdef RCT_NEW_ARCH_ENABLED
      _touchHandler = [RCTSurfaceTouchHandler new];
#else
      _touchHandler = [[RCTTouchHandler alloc] initWithBridge:_bridge];
#endif
    }
    [_touchHandler attachToView:_container];
  }
}

#ifdef RCT_NEW_ARCH_ENABLED
#pragma mark - Fabric Specific

// When the component unmounts we remove it from window's children,
// so when the component gets recycled we need to add it back.
- (void)maybeShow
{
  UIWindow *window = RCTKeyWindow();
  if (![[window subviews] containsObject:self]) {
    [window addSubview:_container];
  }
}

+ (react::ComponentDescriptorProvider)componentDescriptorProvider
{
  return react::concreteComponentDescriptorProvider<react::RNSFullWindowOverlayComponentDescriptor>();
}

- (void)prepareForRecycle
{
  [_container removeFromSuperview];
  // Due to view recycling we don't really want to set _container = nil
  // as it won't be instantiated when the component appears for the second time.
  // We could consider nulling in here & using container (lazy getter) everywhere else.
  // _container = nil;
  [super prepareForRecycle];
}

- (void)mountChildComponentView:(UIView<RCTComponentViewProtocol> *)childComponentView index:(NSInteger)index
{
  // When the component unmounts we remove it from window's children,
  // so when the component gets recycled we need to add it back.
  // As for now it is called here as we lack of method that is called
  // just before component gets restored (from recycle pool).
  [self maybeShow];
  [self addSubview:childComponentView];
}

- (void)unmountChildComponentView:(UIView<RCTComponentViewProtocol> *)childComponentView index:(NSInteger)index
{
  [childComponentView removeFromSuperview];
}

// We do not set frame for ouselves, but rather for the container.
RNS_IGNORE_SUPER_CALL_BEGIN
- (void)updateLayoutMetrics:(react::LayoutMetrics const &)layoutMetrics
           oldLayoutMetrics:(react::LayoutMetrics const &)oldLayoutMetrics
{
  CGRect frame = RCTCGRectFromRect(layoutMetrics.frame);

  // Due to view flattening on new architecture there are situations
  // when we receive frames with origin different from (0, 0).
  // We account for this frame manipulation in shadow node by setting
  // RootNodeKind trait for the shadow node making state consistent
  // between Host & Shadow Tree
  frame.origin = CGPointZero;

  _reactFrame = frame;
  [_container setFrame:frame];
}
RNS_IGNORE_SUPER_CALL_END

- (void)updateProps:(const facebook::react::Props::Shared &)props
           oldProps:(const facebook::react::Props::Shared &)oldProps
{
  const auto &oldComponentProps = *std::static_pointer_cast<const react::RNSFullWindowOverlayProps>(_props);
  const auto &newComponentProps = *std::static_pointer_cast<const react::RNSFullWindowOverlayProps>(props);

  if (newComponentProps.accessibilityContainerViewIsModal != oldComponentProps.accessibilityContainerViewIsModal) {
    [self setAccessibilityContainerViewIsModal:newComponentProps.accessibilityContainerViewIsModal];
  }

  if (newComponentProps.accessibilityEnabled != oldComponentProps.accessibilityEnabled) {
    [self setAccessibilityEnabled:newComponentProps.accessibilityEnabled];
  }

  [super updateProps:props oldProps:oldProps];
}

#else
#pragma mark - Paper specific

- (void)reactSetFrame:(CGRect)frame
{
  _reactFrame = frame;
  [_container setFrame:frame];
}

- (void)invalidate
{
  [_container removeFromSuperview];
  _container = nil;
}

#endif // RCT_NEW_ARCH_ENABLED

@end

#ifdef RCT_NEW_ARCH_ENABLED
Class<RCTComponentViewProtocol> RNSFullWindowOverlayCls(void)
{
  return RNSFullWindowOverlay.class;
}
#endif // RCT_NEW_ARCH_ENABLED

@implementation RNSFullWindowOverlayManager

RCT_EXPORT_MODULE()

RCT_EXPORT_VIEW_PROPERTY(accessibilityContainerViewIsModal, BOOL)
RCT_CUSTOM_VIEW_PROPERTY(accessibilityEnabled, BOOL, RNSFullWindowOverlay)
{
  BOOL value = [RCTConvert BOOL:json];
  view.accessibilityEnabled = value;
}

#ifdef RCT_NEW_ARCH_ENABLED
#else
- (UIView *)view
{
  return [[RNSFullWindowOverlay alloc] initWithBridge:self.bridge];
}
#endif // RCT_NEW_ARCH_ENABLED

@end
