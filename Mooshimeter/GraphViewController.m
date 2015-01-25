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

#import "GraphViewController.h"

@interface GraphViewController ()

@end

@implementation GraphViewController

@synthesize hostView = hostView_;

-(BOOL)prefersStatusBarHidden { return YES; }

-(instancetype)initWithDelegate:(id<ScatterViewControllerDelegate>)delegate {
    self = [super init];
    self.delegate = delegate;
    return self;
}

-(BOOL)shouldAutorotate { return YES; }
- (NSUInteger)supportedInterfaceOrientations { return UIInterfaceOrientationMaskAll; }

#pragma mark - UIViewController lifecycle methods

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    if(UIInterfaceOrientationIsPortrait([[UIDevice currentDevice] orientation])) {
        NSLog(@"Seguing to meter");
        [self.delegate handleScatterViewRotation];
    }
}

-(void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationController.navigationBar.hidden = YES;
    self.config_view = nil;
    if(g_meter->disp_settings.burst_capture) {
        [self graphBuffer];
    } else {
        self->play = YES;
        [self initPlot];
        [self startTrendView];
    }
}

- (void) viewWillDisappear:(BOOL)animated
{
    NSLog(@"Goodbye from scatter...");
    [self pause];
}

-(void)handleBackgroundTap {
    if(g_meter->disp_settings.burst_capture) {
        [self graphBuffer];
    } else {
        self->play = !self->play;
        if(self->play) {
            [self startTrendView];
        } else {
            [self pause];
        }
    }
}

-(void)startTrendView {
    g_meter->meter_settings.rw.calc_settings &=~(METER_CALC_SETTINGS_ONESHOT);
    g_meter->meter_settings.rw.calc_settings |= METER_CALC_SETTINGS_MEAN|METER_CALC_SETTINGS_MS;
    g_meter->meter_settings.rw.target_meter_state = METER_RUNNING;
    
    [g_meter enableStreamMeterBuf:NO cb:^(NSError *error) {
        [g_meter enableStreamMeterSample:YES cb:^(NSError *error) {
            self->start_time = [[NSDate date] timeIntervalSince1970];
            self->buf_i = 0;
            self->buf_n = 0;
            [g_meter sendMeterSettings:^(NSError *error) {
                NSLog(@"Trend mode started");
                [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(redrawTrendView:) userInfo:nil repeats:NO];
            }];
        } update:^{
            [self trendViewUpdate];
        }];
    } complete_buffer_cb:nil];
}

-(void) pause {
    self->play = NO;
    g_meter->meter_settings.rw.target_meter_state = METER_PAUSED;
    [g_meter sendMeterSettings:^(NSError *error) {
        NSLog(@"Paused!");
    }];
}

-(void) trendViewUpdate {
    NSLog(@"Updating measurements...");
    
    // FIXME: This check should go somewhere else...
    if(g_meter->disp_settings.burst_capture) {
        self->play = NO;
        [self pause];
    }
    
    self->time[      buf_i] = [[NSDate date] timeIntervalSince1970] - self->start_time;
    if(g_meter->disp_settings.ac_display[0]) {
        self->ch1_values[buf_i] = [g_meter getRMS:1];
    } else {
        self->ch1_values[buf_i] = [g_meter getMean:1];
    }
    if(g_meter->disp_settings.ac_display[1]) {
        self->ch2_values[buf_i] = [g_meter getRMS:2];
    } else {
        self->ch2_values[buf_i] = [g_meter getMean:2];
    }
    buf_i++;
    buf_i %= N_POINTS_ONSCREEN;
    if(buf_n < N_POINTS_ONSCREEN) buf_n++;
    /*
    if(self->play) {
        [g_meter sendMeterSettings:^(NSError *error) {
            NSLog(@"Finished update");
        }];
    }*/
}

-(void) redrawTrendView:(NSTimer*)timer {
    NSLog(@"Redrawing");
    CPTGraph *graph = self.hostView.hostedGraph;
    [graph reloadData];
    
    CPTXYPlotSpace *ch1Space = (CPTXYPlotSpace*)[graph plotSpaceAtIndex:0];
    
    CPTPlot *ch1Plot         = [graph plotAtIndex:0];
    [ch1Space scaleToFitPlots:[NSArray arrayWithObjects:ch1Plot, nil]];
    
    CPTMutablePlotRange *y1Range = [ch1Space.yRange mutableCopy];
    NSDecimalNumber* tmpDecimalNumber;
    double tmpDouble;
    
    tmpDecimalNumber = [NSDecimalNumber decimalNumberWithDecimal:y1Range.length];
    tmpDouble =[tmpDecimalNumber doubleValue];
    [y1Range expandRangeByFactor:CPTDecimalFromCGFloat(1.2f)];
    ch1Space.yRange = y1Range;
    
    if(!g_meter->disp_settings.xy_mode) {
        CPTXYPlotSpace *ch2Space = (CPTXYPlotSpace*)[graph plotSpaceAtIndex:1];
        CPTPlot *ch2Plot         = [graph plotAtIndex:1];
        [ch2Space scaleToFitPlots:[NSArray arrayWithObjects:ch2Plot, nil]];
        CPTMutablePlotRange *y2Range = [ch2Space.yRange mutableCopy];
        tmpDecimalNumber = [NSDecimalNumber decimalNumberWithDecimal:y2Range.length];
        tmpDouble =[tmpDecimalNumber doubleValue];
        [y2Range expandRangeByFactor:CPTDecimalFromCGFloat(1.2f)];
        
        CPTMutablePlotRange *xRange;
        if(g_meter->disp_settings.channel_disp[0]) {
            xRange = [ch1Space.xRange mutableCopy];
        } else {
            xRange = [ch2Space.xRange mutableCopy];
        }
        [xRange expandRangeByFactor:CPTDecimalFromCGFloat(1.2f)];
        ch1Space.xRange = xRange;
        ch2Space.xRange = xRange;
        ch2Space.yRange = y2Range;
    } else {
        CPTMutablePlotRange *xRange;
        xRange = [ch1Space.xRange mutableCopy];
        [xRange expandRangeByFactor:CPTDecimalFromCGFloat(1.2f)];
        ch1Space.xRange = xRange;
    }
    
    [self redrawAxisLabels];
    
    if(self->play) {
        [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(redrawTrendView:) userInfo:nil repeats:NO];
    }
}

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
                self->ch1_values[i] = [g_meter getValAt:1 i:i];
                self->ch2_values[i] = [g_meter getValAt:2 i:i];
                t+=dt;
            }
            [self initPlot];
        }];
    } update:nil];
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
    self.hostView = [(CPTGraphHostingView *) [CPTGraphHostingView alloc] initWithFrame:self.view.bounds];
    self.hostView.allowPinchScaling = YES;
    
    // Set up the config button
    UIButton* b;
    b = [UIButton buttonWithType:UIButtonTypeSystem];
    b.userInteractionEnabled = YES;
    [b addTarget:self action:@selector(showPlotSettings) forControlEvents:UIControlEventTouchUpInside];
    [b.titleLabel setFont:[UIFont systemFontOfSize:16]];
    [b setTitle:@"Config" forState:UIControlStateNormal];
    [b setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [b setBackgroundColor:[UIColor whiteColor]];
    [b setAlpha:0.5];
    [[b layer] setBorderWidth:2];
    [[b layer] setBorderColor:[UIColor lightGrayColor].CGColor];
    b.frame = CGRectMake(self.view.bounds.size.width-80, self.view.bounds.size.height-40, 80, 40);
    self.config_button = b;
    
    [self.view addSubview:self.hostView];
    [self.view addSubview:b];
}

-(void)showPlotSettings {
    if(!self.config_view) {
        CGRect frame = self.view.frame;
        frame.origin.x += .15*frame.size.width;
        frame.origin.y += .15*frame.size.height;
        frame.size.width  *= 0.7;
        frame.size.height *= 0.7;
        GraphSettingsView* g = [[GraphSettingsView alloc] initWithFrame:frame];
        [g setBackgroundColor:[UIColor whiteColor]];
        [g setAlpha:0.85];
        self.config_view = g;
    }
    if([self.view.subviews containsObject:self.config_view]) {
        [self.config_view removeFromSuperview];
    } else {
        [self.view addSubview:self.config_view];
    }
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
    [ch1PlotSpace scaleToFitPlots:[NSArray arrayWithObjects:ch1Plot, nil]];
    
    CPTMutablePlotRange *y1Range = [ch1PlotSpace.yRange mutableCopy];
    [y1Range expandRangeByFactor:CPTDecimalFromCGFloat(1.2f)];
    ch1PlotSpace.yRange = y1Range;
    
    // 4 - Create styles and symbols
    if( !g_meter->disp_settings.xy_mode ) {
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
    
    
    if( !g_meter->disp_settings.xy_mode ) {
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
        if(g_meter->disp_settings.channel_disp[0]) {
            xRange = [ch1PlotSpace.xRange mutableCopy];
        } else {
            xRange = [ch2PlotSpace.xRange mutableCopy];
        }
        [xRange expandRangeByFactor:CPTDecimalFromCGFloat(1.2f)];
        ch1PlotSpace.xRange = xRange;
        ch2PlotSpace.xRange = xRange;
        
        [y2Range expandRangeByFactor:CPTDecimalFromCGFloat(1.2f)];
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
        [xRange expandRangeByFactor:CPTDecimalFromCGFloat(1.2f)];
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
    if( g_meter->disp_settings.xy_mode ) {
        x.title = [g_meter getDescriptor:2];
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
    y1.title = [g_meter getDescriptor:1];
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
    
    if( !g_meter->disp_settings.xy_mode ) {
        // Create second y axis
        CPTXYAxis *y2 = [[CPTXYAxis alloc]init];
        y2.coordinate = CPTCoordinateY;
        axisSet.axes = [NSArray arrayWithObjects:axisSet.xAxis, axisSet.yAxis, y2, nil];
        y2.axisConstraints = [CPTConstraints constraintWithUpperOffset:20.0];
        y2.plotSpace = self.space2;
        y2.title = [g_meter getDescriptor:2];
        y2.titleTextStyle = ch2AxisTextStyle;
        y2.titleOffset = -35.0f;
        y2.axisLineStyle = axisLineStyle;
        // FIXME: Coreplot not respecting differences in major and minor gridlines
        //y2.minorGridLineStyle = minorGridLineStyle;
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

- (void)drawLabelsForAxis:(CPTXYAxis*)target dbuf:(double*)dbuf {
    CGFloat yMin = dbuf[0];
    for( int i = 0; i < self->buf_n; i++ ) yMin = dbuf[i] < yMin ? dbuf[i]:yMin;
    
    CGFloat yMax = dbuf[0];
    for( int i = 0; i < self->buf_n; i++ ) yMax = dbuf[i] > yMax ? dbuf[i]:yMax;
    
    double range = yMax - yMin;
    
    double majorTick = [self getTickFromRange:range];
    double minorTick = majorTick/5.0;
    yMin = ( majorTick*floor(yMin/majorTick) );
    yMax = ( majorTick*floor(yMax/majorTick) );
    NSMutableSet *yLabels = [NSMutableSet set];
    NSMutableSet *yMajorLocations = [NSMutableSet set];
    NSMutableSet *yMinorLocations = [NSMutableSet set];
    int m = 0;
    double j;
    while(1) {
        j = yMin + minorTick*m;
        if ( ! (m%5) ) {
            CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%3.3f", j] textStyle:target.labelTextStyle];
            NSDecimal location = CPTDecimalFromDouble(j);
            label.tickLocation = location;
            label.offset = -target.majorTickLength - target.labelOffset;
            label.rotation = 3.14/4;
            if (label) {
                [yLabels addObject:label];
            }
            [yMajorLocations addObject:[NSNumber numberWithDouble:j]];
        } else {
            [yMinorLocations addObject:[NSNumber numberWithDouble:j]];
        }
        if( j > yMax && !(m%5) ) break;
        m++;
    }
    target.axisLabels = yLabels;
    target.majorTickLocations = yMajorLocations;
    //y1.minorTickLocations = yMinorLocations;
}

- (void)redrawAxisLabels {
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *) self.hostView.hostedGraph.axisSet;
    
    CPTXYAxis *x = axisSet.xAxis;
    CPTXYAxis *y1 = axisSet.yAxis;
    
    // CONFIGURE Y1
    [self drawLabelsForAxis:y1 dbuf:self->ch1_values];
    
    if( !g_meter->disp_settings.xy_mode ) {
        // CONFIGURE X
        [self drawLabelsForAxis:x dbuf:self->time];
        CPTXYAxis *y2 = axisSet.axes[2];
        // CONFIGURE Y2
        [self drawLabelsForAxis:y2 dbuf:self->ch2_values];
    } else {
        // CONFIGURE X
        [self drawLabelsForAxis:x dbuf:self->ch2_values];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tapButton = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleBackgroundTap)];
    [self.view addGestureRecognizer:self.tapButton];
    self->play = NO;
}

#pragma mark - CPTPlotDataSource methods
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    if ( [plot.identifier isEqual:@"CH1"] == YES
        && !g_meter->disp_settings.channel_disp[0] ) {
        return 0;
    }
    if ( [plot.identifier isEqual:@"CH2"] == YES
        && !g_meter->disp_settings.channel_disp[1] ) {
        return 0;
    }
    return self->buf_n;
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
    double val = 0;
    const int i = (self->buf_i + index) % self->buf_n;
    
    switch (fieldEnum) {
        case CPTScatterPlotFieldX:
            if(g_meter->disp_settings.xy_mode) {
                val = self->ch2_values[i];
            } else {
                val = self->time[i];
            }
            break;
        case CPTScatterPlotFieldY:
            if (        [plot.identifier isEqual:@"CH1"] == YES) {
                val =   self->ch1_values[i];
            } else if ( [plot.identifier isEqual:@"CH2"] == YES) {
                val =   self->ch2_values[i];
            }
            break;
    }

    return [NSNumber numberWithDouble:val];
}

@end
