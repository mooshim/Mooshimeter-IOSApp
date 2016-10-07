/**************************
Mooshimeter iOS App - interface to Mooshimeter wireless multimeter
Copyright (C) 2015  James Whong

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
***************************/

#import "GraphVC.h"
#import "WidgetFactory.h"
#import "GraphSettingsView.h"
#import "GCD.h"

#define BG_COLOR [CPTColor whiteColor]
#define AXIS_COLOR [CPTColor blackColor]
#define LEFT_COLOR [CPTColor redColor]
#define RIGHT_COLOR [CPTColor greenColor]

@implementation XYPoint
+(XYPoint*)make:(float)x y:(float)y {
    XYPoint* rval = [[XYPoint alloc]init];
    rval.x= [NSNumber numberWithFloat:x];
    rval.y= [NSNumber numberWithFloat:y];
    return rval;
}
+(XYPoint*)makeWithNSNumber:(NSNumber*)x y:(NSNumber*)y {
    XYPoint* rval = [[XYPoint alloc]init];
    rval.x= x;
    rval.y= y;
    return rval;
}
@end

@implementation GraphVC

@synthesize hostView = hostView_;

-(BOOL)prefersStatusBarHidden { return YES; }
-(BOOL)shouldAutorotate { return YES; }
-(UIInterfaceOrientationMask)supportedInterfaceOrientations { return UIInterfaceOrientationMaskLandscape; }
-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeRight;
}

#pragma mark - UIViewController lifecycle methods

-(instancetype)initWithMeter:(MooshimeterDeviceBase*)meter {
    self = [super init];
    _meter = meter;

    _max_points_onscreen = 100;
    _xy_mode = NO;
    _buffer_mode = NO;
    _autoscroll = YES;
    _left_axis_auto = YES;
    _right_axis_auto = YES;

    _left_onscreen = [NSMutableArray array];
    _right_onscreen = [NSMutableArray array];
    _left_cache = [NSMutableArray array];
    _right_cache = [NSMutableArray array];

    _sample_time = 0;

    _refresh_timer = nil;

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    [self initPlot];
    [self.meter addDelegate:self];
    [self.meter stream];
    _refresh_timer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                      target:self
                                                    selector:@selector(onRefreshTick)
                                                    userInfo:nil
                                                     repeats:YES];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.meter pause];
    [self.refresh_timer invalidate];
    self.buffer_mode = NO;
    self.navigationController.navigationBar.hidden = NO;
    [self.meter removeDelegate:self];
}

CPTPlotRange* plotRangeForValueArray(NSArray* values, SEL returnsAnNSNumber) {
    if(values.count==0){
        return [CPTPlotRange plotRangeWithLocation:@0 length:@0];
    }
    float minX = CGFLOAT_MAX;
    float maxX = -CGFLOAT_MAX;
    for(id p in values) {
        float x = [(NSNumber*)[p performSelector:returnsAnNSNumber] floatValue];
        if(x > maxX) {maxX= x;}
        if(x < minX)  {minX= x;}
    }
    float dif = maxX-minX;
    if(dif<1e-5) { dif=1e-5; }
    CPTMutablePlotRange *xr = (CPTMutablePlotRange *)[[CPTPlotRange plotRangeWithLocation:[NSNumber numberWithFloat:minX] length:[NSNumber numberWithFloat:dif]] mutableCopy];
    return xr;
}

-(void)fillFromBackingArrayWithXRange:(CPTPlotRange*)range backing_data:(NSMutableArray<XYPoint*>*)backing_data to_fill:(NSMutableArray<XYPoint*>*)to_fill {
    float min = range.locationDouble;
    float max = min+range.lengthDouble;
    [to_fill removeAllObjects];
    for(XYPoint* p in backing_data) {
        float x = [p.x floatValue];
        if(x >= min && x <= max) {
            [to_fill addObject:p];
        }
    }
}

-(void)onRefreshTick {
    if(_left_cache.count==0 || _right_cache.count==0) {
        // If there's no data for us to plot, give up
        return;
    }

    CPTGraph *graph = self.hostView.hostedGraph;
    CPTPlotRange *range;

    if(_xy_mode) {
        // In xy mode, always just grab the latest N readings and autorange both axes
        NSUInteger max_i = MIN(_left_cache.count,_right_cache.count);
        NSUInteger min_i = MAX(max_i-_max_points_onscreen,0);
        [_left_onscreen removeAllObjects];
        [_right_onscreen removeAllObjects];
        for(NSUInteger i = min_i; i < max_i; i++) {
            XYPoint* lp = _left_cache[i];
            XYPoint* rp = _right_cache[i];
            XYPoint* p = [XYPoint makeWithNSNumber:rp.y y:lp.y];
            [_left_onscreen addObject:p];
        }
        // Autorange X dimension
        _leftAxisSpace.xRange = plotRangeForValueArray(_left_onscreen,@selector(x));
    } else {
        // If autoscroll is on, time drives the xrange
        // xrange always drives the data

        // if y autorange is on, data drives the yrange
        // if y autorange is off, the user scales it himself

        // If scroll lock is on, always display the latest data
        // This may seem counter-intuitive, but we do this by setting the bounds we'd like to draw first,
        // then populating the data arrays afterwards.  This is because when we're not scroll locked, the user
        // may arbitrarily adjust the view bounds, so we should fill in our data based on bounds and not vice versa.
        if(_autoscroll||_jump_to_end) {
            // If autoscroll is on, time drives the xrange
            _jump_to_end=NO;
            NSInteger xmin_i = _right_cache.count-_max_points_onscreen;
            if(xmin_i<0) {
                xmin_i = 0;
            }
            float xmin = [((XYPoint*)_right_cache[xmin_i]).x floatValue];
            // Time between samples onscreen depends on whether we're in buffer mode or not
            // If we're in buffer mode, it's the native sample rate of the Mooshimeter
            float dt = _buffer_mode?(1.0f):([self.meter getBufferDepth]);
            dt/= [self.meter getSampleRateHz];
            float xmax = xmin+_max_points_onscreen*dt;
            range = [CPTPlotRange plotRangeWithLocation:[NSNumber numberWithFloat:xmin] length:[NSNumber numberWithFloat:(xmax-xmin)]];
            _leftAxisSpace.xRange = range;
            _rightAxisSpace.xRange = [range copy];
        }

        // xrange always drives the data
        [self fillFromBackingArrayWithXRange:_leftAxisSpace.xRange backing_data:_left_cache to_fill:_left_onscreen];
        [self fillFromBackingArrayWithXRange:_rightAxisSpace.xRange backing_data:_right_cache to_fill:_right_onscreen];
    }

    // if y autorange is on, data drives the yrange
    if(_left_axis_auto) {
        _leftAxisSpace.yRange = plotRangeForValueArray(_left_onscreen,@selector(y));
    }

    if(_right_axis_auto) {
        _rightAxisSpace.yRange = plotRangeForValueArray(_right_onscreen,@selector(y));
    }

    [graph reloadData];
    [self redrawAxisLabels];
}

#pragma mark - Getters/Setters

-(void)setXy_mode:(BOOL)xy_mode {
    _xy_mode = xy_mode;
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.hostView.hostedGraph.axisSet;
    CPTXYAxis *x = axisSet.xAxis;
    CPTXYAxis *y2 = axisSet.axes[2];
    if( self.xy_mode ) {
        x.title = [self.meter getInputLabel:CH2];
        y2.title = @"";
    } else {
        x.title = @"Time [s]";
        y2.title = [self.meter getInputLabel:CH2];
    }
}

-(void)setBuffer_mode:(BOOL)buffer_mode {
    _buffer_mode = buffer_mode;
    self.max_points_onscreen = [self.meter getBufferDepth];
    [self.meter setBufferMode:CH1 on:buffer_mode];
    [self.meter setBufferMode:CH2 on:buffer_mode];
    [self.refresh_button setHidden:!buffer_mode];
}

#pragma mark - Chart behavior
-(void)initPlot {
    NSLog(@"Initializing Plots!");
    [self configureHost];
    [self configureGraph];
    [self configurePlots];
    [self configureAxes];
}

-(void)configureHost {
    for (UIView *subView in self.view.subviews)
    {
        [subView removeFromSuperview];
    }
    self.hostView = [[CPTGraphHostingView alloc] initWithFrame:self.view.bounds];
    self.hostView.allowPinchScaling = YES;
    [self.view addSubview:self.hostView];

    // Set up the config button
    DECLARE_WEAKSELF;
    UIButton* b = [WidgetFactory makeButton:@"Config" callback:^{
        // Open the config popover
        GraphSettingsView* v = [[GraphSettingsView alloc]init];
        [WidgetFactory makePopoverFromView:v size:CGSizeMake(300,300)];
        v.graph = ws;
        v.backgroundColor = [UIColor whiteColor];
    }];
    b.backgroundColor = [UIColor whiteColor];
    b.frame = CGRectMake(0,0,80,40);
    b.frame = [CG alignRight:b.frame to:self.view.bounds];
    b.frame = [CG alignBottom:b.frame to:self.view.bounds];
    self.config_button = b;
    [self.view addSubview:b];

    // Set up the back button
    b = [WidgetFactory makeButton:@"Back" callback:^{
        // Pushed and Modally presented have different dismissal routines.  Because Apple.
        //[ws.navigationController popViewControllerAnimated:YES];
        [ws dismissViewControllerAnimated:YES completion:nil];
    }];
    b.backgroundColor = [UIColor whiteColor];
    b.frame = CGRectMake(0,0,80,40);
    b.frame = [CG alignLeft:b.frame to:self.view.bounds];
    b.frame = [CG alignBottom:b.frame to:self.view.bounds];
    self.config_button = b;
    [self.view addSubview:b];

    // Set up the refresh button (used in buffer mode)
    b = [WidgetFactory makeButton:@"Refresh" callback:^{
        _jump_to_end=YES;
    }];
    b.backgroundColor = [UIColor whiteColor];
    b.frame = CGRectMake(0,0,80,40);
    b.frame = [CG alignRight:b.frame to:self.view.bounds];
    b.frame = [CG alignTop:b.frame to:self.view.bounds];
    self.refresh_button = b;
    [self.view addSubview:b];
    [b setHidden:YES];
}

-(void)configureGraph {
    // 1 - Create the graph
    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:self.hostView.bounds];
    CPTColor *color = [CPTColor colorWithComponentRed:0.15 green:0.15 blue:0.15 alpha:1];
    graph.fill = [CPTFill fillWithColor:color];
    graph.plotAreaFrame.masksToBorder = NO;
    self.hostView.hostedGraph = graph;
#if 0
    // 2 - Set graph title
    
    // 3 - Create and set text style
    CPTMutableTextStyle *titleStyle = [CPTMutableTextStyle textStyle];
    titleStyle.color = [CPTColor whiteColor];
    titleStyle.fontName = @"Helvetica-Bold";
    titleStyle.fontSize = 16.0f;
    graph.titleTextStyle = titleStyle;
    graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    graph.titleDisplacement = CGPointMake(0.0f, 10.0f);
#endif
    // 4 - Set padding for plot area
    graph.paddingLeft = 40;
    graph.paddingRight = 40;
    graph.paddingTop = 0;
    graph.paddingBottom = 40;
    //[graph.plotAreaFrame setPaddingLeft:0.0f];
    //[graph.plotAreaFrame setPaddingBottom:0.0f];
}

-(void)configurePlots {
    // 1 - Get graph and plot space
    CPTGraph *graph = self.hostView.hostedGraph;
    _leftAxisSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;
    _leftAxisSpace.allowsUserInteraction = YES;
    _leftAxisSpace.delegate = self;
    
    // 2 - Create the plots
    CPTScatterPlot *ch1Plot = [[CPTScatterPlot alloc] init];
    ch1Plot.dataSource = self;
    ch1Plot.identifier = @"CH1";
    CPTColor *ch1Color = LEFT_COLOR;
    [graph addPlot:ch1Plot toPlotSpace:_leftAxisSpace];
    
    // 3 - Set up plot space
    [_leftAxisSpace scaleToFitPlots:@[ch1Plot]];
    
    CPTMutablePlotRange *y1Range = [_leftAxisSpace.yRange mutableCopy];
    [y1Range expandRangeByFactor:@1.2f];
    _leftAxisSpace.yRange = y1Range;
    
    // 4 - Create styles and symbols
    if( !self.xy_mode ) {
        CPTMutableLineStyle *ch1LineStyle = [ch1Plot.dataLineStyle mutableCopy];
        ch1LineStyle.lineWidth = 2.5;
        ch1LineStyle.lineColor = ch1Color;
        ch1Plot.dataLineStyle = ch1LineStyle;
        CPTMutableLineStyle *ch1SymbolLineStyle = [CPTMutableLineStyle lineStyle];
        CPTPlotSymbol* ch1Symbol = [[CPTPlotSymbol alloc] init];
        ch1Symbol.lineStyle = ch1SymbolLineStyle;
        ch1SymbolLineStyle.lineColor = ch1Color;
        ch1Plot.plotSymbol = ch1Symbol;
    } else {
        CPTMutableLineStyle *ch1LineStyle = [ch1Plot.dataLineStyle mutableCopy];
        ch1LineStyle.lineWidth = 2.5;
        ch1LineStyle.lineColor = ch1Color;
        ch1Plot.dataLineStyle = nil;
        CPTPlotSymbol* ch1Symbol = [CPTPlotSymbol ellipsePlotSymbol];
        ch1Symbol.fill = [CPTFill fillWithColor:ch1Color];
        ch1Symbol.size = CGSizeMake(5.0f, 5.0f);
        ch1Plot.plotSymbol = ch1Symbol;
    }
    
    
    if( !self.xy_mode ) {
        _rightAxisSpace = [[CPTXYPlotSpace alloc]init];
        _rightAxisSpace.allowsUserInteraction = YES;
        _rightAxisSpace.delegate = self;
        [graph addPlotSpace:_rightAxisSpace];
        
        CPTScatterPlot *ch2Plot = [[CPTScatterPlot alloc] init];
        ch2Plot.dataSource = self;
        ch2Plot.identifier = @"CH2";
        CPTColor *ch2Color = RIGHT_COLOR;
        [graph addPlot:ch2Plot toPlotSpace:_rightAxisSpace];
        
        [_rightAxisSpace scaleToFitPlots:@[ch2Plot]];
        
        CPTMutablePlotRange *y2Range = (CPTMutablePlotRange*)[_rightAxisSpace.yRange mutableCopy];
        
        CPTMutablePlotRange *xRange = (CPTMutablePlotRange*)[_leftAxisSpace.xRange mutableCopy];
        [xRange expandRangeByFactor:@1.2f];
        _leftAxisSpace.xRange = xRange;
        _rightAxisSpace.xRange = xRange;
        
        [y2Range expandRangeByFactor:@1.2f];
        _rightAxisSpace.yRange = y2Range;
        
        CPTMutableLineStyle *ch2LineStyle = (CPTMutableLineStyle*)[ch2Plot.dataLineStyle mutableCopy];
        ch2LineStyle.lineWidth = 2.5;
        ch2LineStyle.lineColor = ch2Color;
        ch2Plot.dataLineStyle = ch2LineStyle;
        CPTMutableLineStyle *ch2SymbolLineStyle = [CPTMutableLineStyle lineStyle];
        ch2SymbolLineStyle.lineColor = ch2Color;
        CPTPlotSymbol *ch2Symbol = nil;
        ch2Symbol.fill = [CPTFill fillWithColor:ch2Color];
        ch2Symbol.lineStyle = ch2SymbolLineStyle;
        ch2Symbol.size = CGSizeMake(6.0f, 6.0f);
        ch2Plot.plotSymbol = ch2Symbol;
    } else {
        CPTMutablePlotRange *xRange;
        xRange = [_leftAxisSpace.xRange mutableCopy];
        [xRange expandRangeByFactor:@1.2f];
        _leftAxisSpace.xRange = xRange;
    }
}

-(double)getTickFromRange:(double)arg {
    double tick = 1e-6;
    BOOL bit = NO;
    while( tick < arg/15.f ) {
        if( bit ) tick *= 2.f;
        else      tick *= 5.f;
        bit = !bit;
    }
    return tick;
}

-(void)configureAxes {
    // 1 - Create styles
    CPTMutableTextStyle *axisTitleStyle = [CPTMutableTextStyle textStyle];
    axisTitleStyle.color = [CPTColor whiteColor];
    axisTitleStyle.fontName = @"Helvetica-Bold";
    axisTitleStyle.fontSize = 12.0f;
    CPTMutableLineStyle *axisLineStyle = [CPTMutableLineStyle lineStyle];
    axisLineStyle.lineWidth = 2.0f;
    axisLineStyle.lineColor = [CPTColor whiteColor];
    
    CPTMutableTextStyle *xAxisTextStyle = [[CPTMutableTextStyle alloc] init];
    xAxisTextStyle.color = [CPTColor whiteColor];
    xAxisTextStyle.fontName = @"Helvetica-Bold";
    xAxisTextStyle.fontSize = 11.0f;
    
    CPTMutableTextStyle *ch1AxisTextStyle = [[CPTMutableTextStyle alloc] init];
    ch1AxisTextStyle.color = LEFT_COLOR;
    ch1AxisTextStyle.fontName = @"Helvetica-Bold";
    ch1AxisTextStyle.fontSize = 11.0f;
    
    CPTMutableTextStyle *ch2AxisTextStyle = [[CPTMutableTextStyle alloc] init];
    ch2AxisTextStyle.color = RIGHT_COLOR;
    ch2AxisTextStyle.fontName = @"Helvetica-Bold";
    ch2AxisTextStyle.fontSize = 11.0f;
    
    CPTMutableLineStyle *tickLineStyle = [CPTMutableLineStyle lineStyle];
    tickLineStyle.lineColor = [CPTColor whiteColor];
    tickLineStyle.lineWidth = 2.0f;
    
    CPTMutableLineStyle *majorGridLineStyle = [CPTMutableLineStyle lineStyle];
    majorGridLineStyle.lineColor = [CPTColor grayColor];
    majorGridLineStyle.lineWidth = 1.0f;
    
    CPTMutableLineStyle *ch1MajorGridLineStyle = [CPTMutableLineStyle lineStyle];
    ch1MajorGridLineStyle.lineColor = [CPTColor colorWithComponentRed:0.4 green:0.0 blue:0.0 alpha:1.0];
    ch1MajorGridLineStyle.lineWidth = 1.0f;
    
    CPTMutableLineStyle *ch2MajorGridLineStyle = [CPTMutableLineStyle lineStyle];
    ch2MajorGridLineStyle.lineColor = [CPTColor colorWithComponentRed:0.0 green:0.4 blue:0.0 alpha:1.0];
    ch2MajorGridLineStyle.lineWidth = 1.0f;

    CPTMutableLineStyle *minorGridLineStyle = [CPTMutableLineStyle lineStyle];
    minorGridLineStyle.lineColor = [CPTColor blackColor];
    minorGridLineStyle.lineWidth = 1.0f;
    
    // 2 - Get axis set
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.hostView.hostedGraph.axisSet;
    
    // 3 - Configure x-axis
    CPTXYAxis *x = axisSet.xAxis;
    x.axisConstraints = [CPTConstraints constraintWithLowerOffset:00.0];
    x.title = @"Time";
    x.titleTextStyle = axisTitleStyle;
    x.titleOffset = 15.0f;
    x.axisLineStyle = axisLineStyle;
    x.minorGridLineStyle = minorGridLineStyle;
    x.majorGridLineStyle = majorGridLineStyle;
    x.labelingPolicy = CPTAxisLabelingPolicyNone;
    x.labelTextStyle = xAxisTextStyle;
    x.majorTickLineStyle = axisLineStyle;
    x.majorTickLength = 4.0f;
    x.tickDirection = CPTSignNegative;

    // 4 - Configure y-axis 1
    CPTXYAxis *y1 = axisSet.yAxis;
    y1.axisConstraints = [CPTConstraints constraintWithLowerOffset:00.0];
    y1.title = [self.meter getInputLabel:CH1];
    y1.titleTextStyle = ch1AxisTextStyle;
    y1.titleOffset = -35.0f;
    y1.axisLineStyle = axisLineStyle;
    // FIXME: Coreplot not respecting differences in major and minor gridlines
    //y.minorGridLineStyle = minorGridLineStyle;
    y1.majorGridLineStyle = ch1MajorGridLineStyle;
    y1.labelingPolicy = CPTAxisLabelingPolicyNone;
    y1.labelTextStyle = ch1AxisTextStyle;
    y1.labelOffset = 35.0f;
    y1.majorTickLineStyle = axisLineStyle;
    y1.majorTickLength = 4.0f;
    y1.minorTickLength = 4.0f;
    y1.tickDirection = CPTSignPositive;

    // Create second y axis
    CPTXYAxis *y2 = [[CPTXYAxis alloc]init];
    y2.coordinate = CPTCoordinateY;
    y2.axisConstraints = [CPTConstraints constraintWithUpperOffset:00.0];
    y2.plotSpace = self.rightAxisSpace;
    y2.title = [self.meter getInputLabel:CH2];
    y2.titleTextStyle = ch2AxisTextStyle;
    y2.titleOffset = -35.0f;
    y2.axisLineStyle = axisLineStyle;
    y2.majorGridLineStyle = ch2MajorGridLineStyle;
    y2.labelingPolicy = CPTAxisLabelingPolicyNone;
    y2.labelTextStyle = ch2AxisTextStyle;
    y2.labelOffset = 30.0f;
    y2.majorTickLineStyle = axisLineStyle;
    y2.majorTickLength = 4.0f;
    y2.minorTickLength = 4.0f;
    y2.tickDirection = CPTSignNegative;

    // Add the y2 axis
    axisSet.axes = @[axisSet.xAxis, axisSet.yAxis, y2];

    [self redrawAxisLabels];
}

- (void)drawLabelsForAxis:(CPTXYAxis*)target cpt_range:(CPTPlotRange*)cpt_range{
    double majorTick = [self getTickFromRange:[cpt_range.length floatValue]];
    float yMin = (float)(        majorTick*floor(cpt_range.locationDouble/majorTick) );
    float yMax = (float)( yMin + cpt_range.lengthDouble );
    NSMutableSet *yLabels = [NSMutableSet set];
    NSMutableSet *yMajorLocations = [NSMutableSet set];
    for(double j = yMin; j < yMax; j+=majorTick) {
        CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%3.3f", j] textStyle:target.labelTextStyle];
        label.tickLocation = [NSNumber numberWithDouble:j];
        label.offset = -target.majorTickLength - target.labelOffset;
        label.rotation = 3.14f/4; // Rotate 45 degrees for better fit
        if (label) {
            [yLabels addObject:label];
        }
        [yMajorLocations addObject:[NSNumber numberWithDouble:j]];
    }
    target.axisLabels = yLabels;
    target.majorTickLocations = yMajorLocations;
}

- (void)redrawAxisLabels {
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.hostView.hostedGraph.axisSet;
    
    CPTXYAxis *x = axisSet.xAxis;
    CPTXYAxis *y1 = axisSet.yAxis;
    CPTXYAxis *y2 = axisSet.axes[2];

    [self drawLabelsForAxis:x cpt_range:_leftAxisSpace.xRange];
    [self drawLabelsForAxis:y1 cpt_range:_leftAxisSpace.yRange];
    [self drawLabelsForAxis:y2 cpt_range:_rightAxisSpace.yRange];
}

#pragma mark - CPTPlotDataSource methods
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    if ( [plot.identifier isEqual:@"CH1"] ) {
        return self.left_onscreen.count;
    }
    if ( [plot.identifier isEqual:@"CH2"] ) {
        return self.right_onscreen.count;
    }
    return 0;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
    NSMutableArray<XYPoint *>* source;
    if([plot.identifier isEqual:@"CH1"]) {
        source = _left_onscreen;
    } else if([plot.identifier isEqual:@"CH2"]) {
        source = _right_onscreen;
    } else {
        NSLog(@"WHAT");
    }

    XYPoint* p = source[index];

    switch (fieldEnum) {
        case CPTScatterPlotFieldX:
            return p.x;
        case CPTScatterPlotFieldY:
            return p.y;
    }
    // Should never get here
    return nil;
}

#pragma mark - MooshimeterDelegateProtocol methods

void erroneousintercept() {
    NSLog(@"IMPOSIBRUUUU");
}

- (void)onInit {erroneousintercept();}
- (void)onRssiReceived:(int)rssi {}
- (void)onBatteryVoltageReceived:(float)voltage {}
- (void)onSampleRateChanged:(int)sample_rate_hz {erroneousintercept();}
- (void)onBufferDepthChanged:(int)buffer_depth {erroneousintercept();}
- (void)onLoggingStatusChanged:(BOOL)on new_state:(int)new_state message:(NSString *)message {}
- (void)onRangeChange:(Channel)c new_range:(RangeDescriptor *)new_range {erroneousintercept();}
- (void)onInputChange:(Channel)c descriptor:(InputDescriptor *)descriptor {erroneousintercept();}
- (void)onOffsetChange:(Channel)c offset:(MeterReading *)offset {erroneousintercept();}
// Delegate calls we actually care about
- (void)onDisconnect {
    [self.navigationController popToRootViewControllerAnimated:YES];
}
- (void)onSampleReceived:(double)timestamp_utc c:(Channel)c val:(MeterReading *)val {
    // Can't trust timestamp_utc, it's being generated by the processor which tends to bunch readings up
    NSMutableArray * buf=nil;
    switch(c){
        case CH1:
            buf=self.left_cache;
            break;
        case CH2:
            buf= self.right_cache;
            break;
        case MATH:
            // We don't handle this yet
            return;
    }
    if(buf==nil){return;} // Might happen with math channel
    [GCD asyncMain:^{
        [buf addObject:[XYPoint make:_sample_time y:val.value]];
        if(c==CH2) {
            //FIXME: This is a hack to get around the fact that we can't get accurate timestamps from iOS
            // The tendency is for readings to bunch up between renders because they are timestamped with the time at which
            // the processor can service them.  We don't care much about absolute time, so let's synthesize the time for now.
            _sample_time += (double)[self.meter getBufferDepth]/[self.meter getSampleRateHz];
        }
    }];
}
- (void)onBufferReceived:(double)timestamp_utc c:(Channel)c dt:(float)dt val:(NSArray<NSNumber *> *)val {
    // Just shuttle the data in to cache
    NSMutableArray * buf=nil;
    switch(c){
        case CH1:
            buf=self.left_cache;
            break;
        case CH2:
            buf= self.right_cache;
            break;
        case MATH:
            // We don't handle this yet
            return;
    }
    if(buf==nil){return;} // Might happen with math channel
    [GCD asyncMain:^{
        float t = _sample_time;
        for(NSNumber* n in val) {
            XYPoint * p = [XYPoint makeWithNSNumber:[NSNumber numberWithFloat:t] y:n];
            [buf addObject:p];
            t+=dt;
        }
        if(c==CH2) {
            //FIXME: This is a hack to get around the fact that we can't get accurate timestamps from iOS
            // The tendency is for readings to bunch up between renders because they are timestamped with the time at which
            // the processor can service them.  We don't care much about absolute time, so let's synthesize the time for now.
            _sample_time += (double)[self.meter getBufferDepth]/[self.meter getSampleRateHz];
        }
    }];
}
#pragma mark CPTPlotSpaceDelegate methods

-(BOOL)plotSpace:(nonnull CPTPlotSpace *)space shouldScaleBy:(CGFloat)interactionScale aboutPoint:(CGPoint)interactionPoint {
    // Respect the autorange settings
    if(    space == _leftAxisSpace
        && _left_axis_auto ) {
        return NO;
    }
    if(    space == _rightAxisSpace
            && _right_axis_auto ) {
        return NO;
    }
    // If both axes are manual ranging, distinguish which to modify based on where the interactionpoint is
    // (left pinch changes left axis, right pinch changes right axis)
    if(!_left_axis_auto && !_right_axis_auto) {
        // Determine what side of the screen was pinched
        BOOL left_side_pinched = interactionPoint.x < self.hostView.frame.size.width/2;
        BOOL left_side_being_tested = space==_leftAxisSpace;
        if(left_side_being_tested!=left_side_pinched) {
            return NO;
        }
    }

    CPTXYPlotSpace *xyspace = (CPTXYPlotSpace *)space;
    CPTMutablePlotRange *y = [[xyspace yRange] mutableCopy];

    // Figure out how to offset the range
    // interactionPoint is in pixels, but with Y inverted from the native scheme
    // This is how far up the view the interaction occurred, with 1 being the top
    double how_far_up = interactionPoint.y/self.hostView.frame.size.height;

    // This is how much the range has changed
    double range_change = y.lengthDouble*(1/interactionScale - 1);
    // If the gesture is at the top of the view, the entire change gets applied to the range.location (which specifies bottom)
    y.locationDouble = y.locationDouble-(range_change*(how_far_up));

    // Scaling is easy
    y.lengthDouble = y.lengthDouble/interactionScale;

    xyspace.yRange = y;
    return NO;
}
-(BOOL)plotSpace:(nonnull CPTPlotSpace *)space shouldHandlePointingDeviceDownEvent:(nonnull CPTNativeEvent *)event atPoint:(CGPoint)point {
    _left_side_touched = point.x < self.hostView.frame.size.width/2;
    return YES;
}
-(CGPoint)plotSpace:(nonnull CPTPlotSpace *)space willDisplaceBy:(CGPoint)proposedDisplacementVector {
    if(_autoscroll) {
        // If scroll lock is on, don't allow scrolling in X
        proposedDisplacementVector.x = 0;
    }
    if(    space == _leftAxisSpace
            && _left_axis_auto ) {
        proposedDisplacementVector.y = 0;
    }
    if(    space == _rightAxisSpace
            && _right_axis_auto ) {
        proposedDisplacementVector.y = 0;
    }
    // If both axes are manual ranging, distinguish which to modify based on where the interactionpoint is
    // (left pinch changes left axis, right pinch changes right axis)
    if(!_left_axis_auto && !_right_axis_auto) {
        // Determine what side of the screen was pinched
        BOOL left_side_being_tested = space==_leftAxisSpace;
        if(left_side_being_tested!=_left_side_touched) {
            proposedDisplacementVector.y = 0;
        }
    }

    return proposedDisplacementVector;
}

@end
