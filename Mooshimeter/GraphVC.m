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

@implementation XYPoint
+(XYPoint*)make:(float)x y:(float)y {
    XYPoint* rval = [[XYPoint alloc]init];
    rval.x= [NSNumber numberWithFloat:x];
    rval.y= [NSNumber numberWithFloat:y];
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
    self.meter = meter;

    self.max_points_onscreen = 1024;
    self.xy_mode = NO;
    self.buffer_mode = NO;
    self.ch1_on = YES;
    self.ch2_on = YES;
    self.math_on = NO;
    self.scroll_lock = YES;
    self.left_axis_auto = YES;
    self.right_axis_auto = YES;

    self.left_vals = [[NSMutableArray alloc] init];;
    self.right_vals = [[NSMutableArray alloc] init];;

    self.start_time = (double)[[NSDate date] timeIntervalSince1970];;

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tapButton = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBackgroundTap)];
    [self.view addGestureRecognizer:self.tapButton];
    NSNumber *value = [NSNumber numberWithInt:UIInterfaceOrientationLandscapeRight];
    [[UIDevice currentDevice] setValue:value forKey:@"orientation"];
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    [self initPlot];
    [self.meter setDelegate:self];
    [self.meter stream];
}

- (void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.meter pause];
    self.navigationController.navigationBar.hidden = NO;
}

-(void)handleBackgroundTap {
    if([self.meter isStreaming]) {
        [self.meter pause];
    } else {
        [self.meter stream];
    }
}

-(void) redrawTrendView {
    CPTGraph *graph = self.hostView.hostedGraph;
    [graph reloadData];
    
    CPTXYPlotSpace *ch1Space = (CPTXYPlotSpace*)[graph plotSpaceAtIndex:0];
    
    CPTPlot *ch1Plot         = [graph plotAtIndex:0];
    [ch1Space scaleToFitPlots:@[ch1Plot]];
    
    CPTMutablePlotRange *y1Range = (CPTMutablePlotRange *)[ch1Space.yRange mutableCopy];
    
    [y1Range expandRangeByFactor:@1.2f];
    ch1Space.yRange = y1Range;
    
    if(!self.xy_mode) {
        CPTXYPlotSpace *ch2Space = (CPTXYPlotSpace*)[graph plotSpaceAtIndex:1];
        CPTPlot *ch2Plot         = [graph plotAtIndex:1];
        [ch2Space scaleToFitPlots:@[ch2Plot]];
        CPTMutablePlotRange *y2Range = (CPTMutablePlotRange *)[ch2Space.yRange mutableCopy];
        [y2Range expandRangeByFactor:@1.2f];
        
        CPTMutablePlotRange *xRange;
        if(self.ch1_on) {
            xRange = (CPTMutablePlotRange *)[ch1Space.xRange mutableCopy];
        } else {
            xRange = (CPTMutablePlotRange *)[ch2Space.xRange mutableCopy];
        }
        [xRange expandRangeByFactor:@1.2f];
        ch1Space.xRange = xRange;
        ch2Space.xRange = xRange;
        ch2Space.yRange = y2Range;
    } else {
        CPTMutablePlotRange *xRange;
        xRange = (CPTMutablePlotRange *)[ch1Space.xRange mutableCopy];
        [xRange expandRangeByFactor:@1.2f];
        ch1Space.xRange = xRange;
    }
    
    [self redrawAxisLabels];
}
#if 0
-(void) graphBuffer {
    g_meter->meter_settings.rw.calc_settings &=~(METER_CALC_SETTINGS_MS|METER_CALC_SETTINGS_MEAN);
    g_meter->meter_settings.rw.calc_settings |= METER_CALC_SETTINGS_ONESHOT;
    g_meter->meter_settings.rw.target_meter_state = METER_RUNNING;
    
    // Bring up a loading icon
    CGRect                  b = self.view.bounds;
    UIActivityIndicatorView* indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    //center the indicator in the view
    indicator.frame = CGRectMake((b.size.width-20)/2,(b.size.height-20)/2,20,20);
    [self.view addSubview:indicator];
    [indicator startAnimating];
    
    [g_meter enableStreamMeterSample:NO cb:^(NSError *error) {
        [g_meter enableStreamMeterBuf:YES cb:^(NSError *error) {
            [g_meter sendMeterSettings:^(NSError *error) {
                NSLog(@"Capture setup complete!");
            }];
        } complete_buffer_cb:^{
            // Load data from meter
            // FIXME: Super memory inefficient
            double t = 0;
            int freq = 125;
            freq <<= (g_meter->meter_settings.rw.adc_settings & ADC_SETTINGS_SAMPLERATE_MASK);
            double dt = 1./((double)(freq));
            
            self->buf_i = 0;
            self->buf_n = [g_meter getBufLen];
            
            for( int i = 0; i < [g_meter getBufLen]; i++ ) {
                time[i] = t;
                self->ch1_values[i] = [g_meter getValAt:0 i:i];
                self->ch2_values[i] = [g_meter getValAt:1 i:i];
                t+=dt;
            }
            [self initPlot];
        }];
    } update:nil];
}
#endif
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
    UIButton* b = [WidgetFactory makeButton:@"Config" callback:^{
        // Open the config popover
        UIView* v = [WidgetFactory makePopoverFromView:[GraphSettingsView class]size:CGSizeMake(300,300)];
        v.backgroundColor = [UIColor whiteColor];
    }];
    b.backgroundColor = [UIColor whiteColor];
    b.frame = CGRectMake(0,0,80,40);
    b.frame = [CG alignRight:b.frame to:self.view.bounds];
    b.frame = [CG alignBottom:b.frame to:self.view.bounds];
    self.config_button = b;
    [self.view addSubview:b];

    // Set up the back button
    __weak typeof(self) ws = self;
    b = [WidgetFactory makeButton:@"Back" callback:^{
        // Pushed and Modally presented have different dismissal routines.  Because apple.
        //[ws.navigationController popViewControllerAnimated:YES];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    b.backgroundColor = [UIColor whiteColor];
    b.frame = CGRectMake(0,0,80,40);
    b.frame = [CG alignLeft:b.frame to:self.view.bounds];
    b.frame = [CG alignBottom:b.frame to:self.view.bounds];
    self.config_button = b;
    [self.view addSubview:b];
}

-(void)configureGraph {
    // 1 - Create the graph
    CPTGraph *graph = [[CPTXYGraph alloc] initWithFrame:self.hostView.bounds];
    CPTColor *color = [CPTColor colorWithComponentRed:0.15 green:0.15 blue:0.15 alpha:1];
    graph.fill = [CPTFill fillWithColor:color];
    graph.plotAreaFrame.masksToBorder = NO;
    self.hostView.hostedGraph = graph;
    
    // 2 - Set graph title
    
    // 3 - Create and set text style
    CPTMutableTextStyle *titleStyle = [CPTMutableTextStyle textStyle];
    titleStyle.color = [CPTColor whiteColor];
    titleStyle.fontName = @"Helvetica-Bold";
    titleStyle.fontSize = 16.0f;
    graph.titleTextStyle = titleStyle;
    graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    graph.titleDisplacement = CGPointMake(0.0f, 10.0f);
    // 4 - Set padding for plot area
    [graph.plotAreaFrame setPaddingLeft:0.0f];
    [graph.plotAreaFrame setPaddingBottom:0.0f];
}

-(void)configurePlots {
    // 1 - Get graph and plot space
    CPTGraph *graph = self.hostView.hostedGraph;
    CPTXYPlotSpace *ch1PlotSpace = (CPTXYPlotSpace *) graph.defaultPlotSpace;
    
    ch1PlotSpace.allowsUserInteraction = YES;
    
    // 2 - Create the plots
    CPTScatterPlot *ch1Plot = [[CPTScatterPlot alloc] init];
    ch1Plot.dataSource = self;
    ch1Plot.identifier = @"CH1";
    CPTColor *ch1Color = [CPTColor redColor];
    [graph addPlot:ch1Plot toPlotSpace:ch1PlotSpace];
    
    // 3 - Set up plot space
    [ch1PlotSpace scaleToFitPlots:@[ch1Plot]];
    
    CPTMutablePlotRange *y1Range = [ch1PlotSpace.yRange mutableCopy];
    [y1Range expandRangeByFactor:@1.2f];
    ch1PlotSpace.yRange = y1Range;
    
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
        CPTXYPlotSpace *ch2PlotSpace = [[CPTXYPlotSpace alloc]init];
        ch2PlotSpace.allowsUserInteraction = YES;
        self.space2 = ch2PlotSpace;
        [graph addPlotSpace:ch2PlotSpace];
        
        CPTScatterPlot *ch2Plot = [[CPTScatterPlot alloc] init];
        ch2Plot.dataSource = self;
        ch2Plot.identifier = @"CH2";
        CPTColor *ch2Color = [CPTColor greenColor];
        [graph addPlot:ch2Plot toPlotSpace:ch2PlotSpace];
        
        [ch2PlotSpace scaleToFitPlots:[NSArray arrayWithObjects:ch2Plot, nil]];
        
        CPTMutablePlotRange *y2Range = [ch2PlotSpace.yRange mutableCopy];
        
        CPTMutablePlotRange *xRange;
        if(self.ch1_on) {
            xRange = [ch1PlotSpace.xRange mutableCopy];
        } else {
            xRange = [ch2PlotSpace.xRange mutableCopy];
        }
        [xRange expandRangeByFactor:@1.2f];
        ch1PlotSpace.xRange = xRange;
        ch2PlotSpace.xRange = xRange;
        
        [y2Range expandRangeByFactor:@1.2f];
        ch2PlotSpace.yRange = y2Range;
        
        CPTMutableLineStyle *ch2LineStyle = [ch2Plot.dataLineStyle mutableCopy];
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
        xRange = [ch1PlotSpace.xRange mutableCopy];
        [xRange expandRangeByFactor:@1.2f];
        ch1PlotSpace.xRange = xRange;
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
    ch1AxisTextStyle.color = [CPTColor redColor];
    ch1AxisTextStyle.fontName = @"Helvetica-Bold";
    ch1AxisTextStyle.fontSize = 11.0f;
    
    CPTMutableTextStyle *ch2AxisTextStyle = [[CPTMutableTextStyle alloc] init];
    ch2AxisTextStyle.color = [CPTColor greenColor];
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
    x.axisConstraints = [CPTConstraints constraintWithLowerOffset:10.0];
    if( self.xy_mode ) {
        x.title = [self.meter getInputLabel:CH2];
    } else {
        x.title = @"Time";
    }
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
    y1.axisConstraints = [CPTConstraints constraintWithLowerOffset:20.0];
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
    
    if( !self.xy_mode ) {
        // Create second y axis
        CPTXYAxis *y2 = [[CPTXYAxis alloc]init];
        y2.coordinate = CPTCoordinateY;
        axisSet.axes = [NSArray arrayWithObjects:axisSet.xAxis, axisSet.yAxis, y2, nil];
        y2.axisConstraints = [CPTConstraints constraintWithUpperOffset:20.0];
        y2.plotSpace = self.space2;
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
    }
    
    [self redrawAxisLabels];
}

- (void)drawLabelsForAxis:(CPTXYAxis*)target values:(NSMutableArray<XYPoint*>*)values use_yvalues:(bool)use_yvalues{
    if(values.count==0) {
        // Nothing we can do, no data provided
        return;
    }
    float (^getter)(NSUInteger i);
    if(use_yvalues) {
        getter = ^float(NSUInteger i) {return ((XYPoint*)values[i]).y.floatValue;};
    } else {
        getter = ^float(NSUInteger i) {return ((XYPoint*)values[i]).x.floatValue;};
    }
    CGFloat yMin = getter(0);
    for( NSUInteger i = 0; i < values.count; i++ ) yMin = getter(i) < yMin ? getter(i):yMin;
    
    CGFloat yMax = getter(0);
    for( NSUInteger i = 0; i < values.count; i++ ) yMax = getter(i) > yMax ? getter(i):yMax;
    
    double range = yMax - yMin;
    
    double majorTick = [self getTickFromRange:range];
    yMin = (float)( majorTick*floor(yMin/majorTick) );
    yMax = (float)( majorTick*floor(yMax/majorTick) );
    NSMutableSet *yLabels = [NSMutableSet set];
    NSMutableSet *yMajorLocations = [NSMutableSet set];
    for(double j = yMin; j < yMax; j+=majorTick) {
        CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%3.3f", j] textStyle:target.labelTextStyle];
        label.tickLocation = [NSNumber numberWithDouble:j];
        j;
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
    
    // CONFIGURE Y1
    [self drawLabelsForAxis:y1 values:self.left_vals use_yvalues:YES];
    
    if( !self.xy_mode ) {
        // CONFIGURE X
        [self drawLabelsForAxis:x values:self.left_vals use_yvalues:NO];
        CPTXYAxis *y2 = axisSet.axes[2];
        // CONFIGURE Y2
        [self drawLabelsForAxis:y2 values:self.right_vals use_yvalues:YES];
    } else {
        // CONFIGURE X
        [self drawLabelsForAxis:x values:self.right_vals use_yvalues:YES];
    }
}

#pragma mark - CPTPlotDataSource methods
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    if ( [plot.identifier isEqual:@"CH1"] ) {
        if(self.ch1_on) {
            return self.left_vals.count;
        } else {
            return 0;
        }
    }
    if ( [plot.identifier isEqual:@"CH2"] ) {
        if(self.ch2_on) {
            return self.right_vals.count;
        } else {
            return 0;
        }
    }
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
    double val = 0;

    NSMutableArray<XYPoint *>* source;
    if([plot.identifier isEqual:@"CH1"]) {
        source = self.left_vals;
    } else if([plot.identifier isEqual:@"CH2"]) {
        source = self.right_vals;
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

- (void)onInit {NSLog(@"IMPOSIBRUUUU");}
- (void)onRssiReceived:(int)rssi {}
- (void)onBatteryVoltageReceived:(float)voltage {}
- (void)onSampleRateChanged:(int)sample_rate_hz {NSLog(@"IMPOSIBRUUUU");}
- (void)onBufferDepthChanged:(int)buffer_depth {NSLog(@"IMPOSIBRUUUU");}
- (void)onLoggingStatusChanged:(bool)on new_state:(int)new_state message:(NSString *)message {}
- (void)onRangeChange:(Channel)c new_range:(RangeDescriptor *)new_range {NSLog(@"IMPOSIBRUUUU");}
- (void)onInputChange:(Channel)c descriptor:(InputDescriptor *)descriptor {NSLog(@"IMPOSIBRUUUU");}
- (void)onOffsetChange:(Channel)c offset:(MeterReading *)offset {NSLog(@"IMPOSIBRUUUU");}
// Delegate calls we actually care about
- (void)onDisconnect {
    [self.navigationController popToRootViewControllerAnimated:YES];
}
- (void)onSampleReceived:(double)timestamp_utc c:(Channel)c val:(MeterReading *)val {
    // Can't trust this timestamp, we're generating it locally so the data's real spikey
    NSMutableArray * buf=nil;
    switch(c){
        case CH1:
            buf=self.left_vals;
            break;
        case CH2:
            buf=self.right_vals;
            break;
        case MATH:
            // We don't handle this yet
            return;
    }
    if(buf==nil){NSLog(@"wat");return;} // Should never happen
    float dt = (float)(timestamp_utc - self.start_time);
    [buf addObject:[XYPoint make:dt y:val.value]];
    while(buf.count>self.max_points_onscreen) {
        [buf removeObjectAtIndex:0];
    }
    [self redrawTrendView];
}
- (void)onBufferReceived:(double)timestamp_utc c:(Channel)c dt:(float)dt val:(NSArray<NSNumber *> *)val {

}
@end
