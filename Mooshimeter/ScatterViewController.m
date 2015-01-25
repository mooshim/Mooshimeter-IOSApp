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

#import "ScatterViewController.h"

@interface ScatterViewController ()

@end

@implementation ScatterViewController

@synthesize hostView = hostView_;

-(BOOL)prefersStatusBarHidden { return YES; }

- (void)setDevice:(MooshimeterDevice*)device
{
    self.meter = device;
}

#pragma mark - AlertView delegate

-(void)invokeMegaAnnoyingPopup
{
    NSLog(@"Bring out the popup");
    self.megaAlert = [[[UIAlertView alloc] initWithTitle:@"Loading..."
                        message:@"Loading" delegate:self cancelButtonTitle:@"Cancel"
                        otherButtonTitles: nil] init];
    
    [self.megaAlert show];
}

-(void)dismissMegaAnnoyingPopup
{
    [self.megaAlert dismissWithClickedButtonIndex:0 animated:YES];
    self.megaAlert = nil;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self dismissMegaAnnoyingPopup];
}

#pragma mark - UIViewController lifecycle methods

- (void) viewWillAppear:(BOOL)animated {
    NSLog(@"Trend View about to appear");
    [super viewWillAppear:animated];
    self->meter_settings = self.meter->meter_settings;
    self.meter->meter_settings.rw.calc_settings  = 0x17; // buffer depth 128, mean calc on, ac calc off, freq calc off
    //[self.meter sendMeterSettings:self cb:@selector(redraw_graph) arg:nil];
    [self invokeMegaAnnoyingPopup];
}

-(void) redraw_graph {
    
    //[self.meter downloadSampleBuffer:self cb:@selector(initPlot) arg:nil];
}

- (void) viewWillDisappear:(BOOL)animated
{
    NSLog(@"Restoring settings...");
    // Stash the present settings... in pure multimeter mode we use pure settings
    self.meter->meter_settings = self->meter_settings;
    //[self.meter sendMeterSettings:nil cb:nil arg:nil];
}

#pragma mark - Chart behavior
-(void)initPlot {
    NSLog(@"Initializing Plots!");
    // Load data from meter
    // FIXME: Super memory inefficient
    double t = 0;
    int freq = 125;
    freq <<= (self.meter->meter_settings.rw.adc_settings & 0x07);
    double dt = 1./((double)(freq));

    for( int i = 0; i < [self.meter getBufLen]; i++ ) {
        time[i] = t;
        self->ch1_values[i] = [self.meter getCH1Value:i];
        self->ch2_values[i] = [self.meter getCH2Value:i];
        t+=dt;
    }
    [self configureHost];
    [self configureGraph];
    [self configurePlots];
    [self configureAxes];
    [self dismissMegaAnnoyingPopup];
    //[self redraw_graph];
}

-(void)configureHost {
    for (UIView *subView in self.view.subviews)
    {
        [subView removeFromSuperview];
    }
    self.hostView = [(CPTGraphHostingView *) [CPTGraphHostingView alloc] initWithFrame:self.view.bounds];
    self.hostView.allowPinchScaling = YES;
    [self.view addSubview:self.hostView];
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
    CPTColor *ch1Color = [CPTColor whiteColor];
    [graph addPlot:ch1Plot toPlotSpace:ch1PlotSpace];
    
    // 3 - Set up plot space
    [ch1PlotSpace scaleToFitPlots:[NSArray arrayWithObjects:ch1Plot, nil]];
    
    CPTMutablePlotRange *xRange = [ch1PlotSpace.xRange mutableCopy];
    [xRange expandRangeByFactor:CPTDecimalFromCGFloat(1.2f)];
    ch1PlotSpace.xRange = xRange;
    
    CPTMutablePlotRange *y1Range = [ch1PlotSpace.yRange mutableCopy];
    [y1Range expandRangeByFactor:CPTDecimalFromCGFloat(1.2f)];
    ch1PlotSpace.yRange = y1Range;
    
    // 4 - Create styles and symbols
    if( !self.meter->disp_settings.xy_mode ) {
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
    
    
    if( !self.meter->disp_settings.xy_mode ) {
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
        
        //[xRange expandRangeByFactor:CPTDecimalFromCGFloat(1.2f)];
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
    if( self.meter->disp_settings.xy_mode ) {
        x.title = [self.meter getCH2Label];
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
    y1.title = [self.meter getCH1Label];
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
    
    if( !self.meter->disp_settings.xy_mode ) {
        // Create second y axis
        CPTXYAxis *y2 = [[CPTXYAxis alloc]init];
        y2.coordinate = CPTCoordinateY;
        axisSet.axes = [NSArray arrayWithObjects:axisSet.xAxis, axisSet.yAxis, y2, nil];
        y2.axisConstraints = [CPTConstraints constraintWithUpperOffset:20.0];
        y2.plotSpace = self.space2;
        y2.title = [self.meter getCH2Label];
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
    for( int i = 0; i < N_ADC_SAMPLES; i++ ) yMin = dbuf[i] < yMin ? dbuf[i]:yMin;
    
    CGFloat yMax = dbuf[0];
    for( int i = 0; i < N_ADC_SAMPLES; i++ ) yMax = dbuf[i] > yMax ? dbuf[i]:yMax;
    
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
    
    if( !self.meter->disp_settings.xy_mode ) {
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

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tapButton = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showTabBar)];
    [self.view addGestureRecognizer:self.tapButton];
    [self.tabBarController.tabBar setHidden:YES];
}

-(void) showTabBar {
    static bool hidden=YES;
    hidden = !hidden;
    [self.tabBarController.tabBar setHidden:hidden];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    NSLog(@"Rotated!");
    [self initPlot];
}

#pragma mark - CPTPlotDataSource methods
-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot {
    return [self.meter getBufLen]; // FIXME I WISH ONLY FOR DEATH
}

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index {
    double val;
    switch (fieldEnum) {
        case CPTScatterPlotFieldX:
            if(self.meter->disp_settings.xy_mode) {
                val =   self->ch2_values[index];
                return  [NSNumber numberWithDouble:val];
            } else {
                val = self->time[index];
                return [NSNumber numberWithDouble:val];
            }
            break;
            
        case CPTScatterPlotFieldY:
            if (        [plot.identifier isEqual:@"CH1"] == YES) {
                val =   self->ch1_values[index];
                return  [NSNumber numberWithDouble:val];
            } else if ( [plot.identifier isEqual:@"CH2"] == YES) {
                val =   self->ch2_values[index];
                return  [NSNumber numberWithDouble:val];
            }
            break;
    }
    return [NSDecimalNumber zero];
}

@end
