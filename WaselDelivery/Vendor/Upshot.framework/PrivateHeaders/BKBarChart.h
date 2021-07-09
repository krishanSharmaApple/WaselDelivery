//
//  PNBarChart.h
//  PNChartDemo
//
//  Created by kevin on 11/7/13.
//  Copyright (c) 2013年 kevinzhow. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Upshot/BKGenericChart.h>
#import <Upshot/BKChartDelegate.h>
#import <Upshot/BKBar.h>

#define kXLabelMargin 15
#define kYLabelMargin 15
#define kYLabelHeight 15
#define kXLabelHeight 20

typedef NSString *(^PNYLabelFormatter)(CGFloat yLabelValue);

@interface BKBarChart : BKGenericChart

/**
 * Draws the chart in an animated fashion.
 */
- (void)strokeChart;

@property (nonatomic) NSArray *xLabels;
@property (nonatomic) NSArray *yLabels;
@property (nonatomic) NSArray *yValues;

@property (nonatomic) NSMutableArray * bars;

@property (nonatomic) CGFloat xLabelWidth;
@property (nonatomic) int yValueMax;
@property (nonatomic) UIColor *strokeColor;
@property (nonatomic) UIColor *percentageColor;
@property (nonatomic) NSArray *strokeColors;


/** Update Values. */
- (void)updateChartData:(NSArray *)data;

- (void)updateBarColor:(UIColor *)color atIndex:(NSInteger)index;

- (void)zoomInAndZoomOutUserBar:(NSInteger)index;

- (void)animateUserBar:(NSInteger)index;

- (void)showPercentagesOnbar:(NSInteger)totalRespons values:(NSArray *)values;

/** Changes chart margin. */
@property (nonatomic) CGFloat yChartLabelWidth;

/** Formats the ylabel text. */
@property (copy) PNYLabelFormatter yLabelFormatter;

@property (nonatomic) CGFloat chartMargin;

/** Controls whether labels should be displayed. */
@property (nonatomic) BOOL showLabel;

/** Controls whether the chart border line should be displayed. */
@property (nonatomic) BOOL showChartBorder;

/** Chart bottom border, co-linear with the x-axis. */
@property (nonatomic) CAShapeLayer * chartBottomLine;

/** Chart left border, co-linear with the y-axis. */
@property (nonatomic) CAShapeLayer * chartLeftLine;

/** Corner radius for all bars in the chart. */
@property (nonatomic) CGFloat barRadius;

/** Width of all bars in the chart. */
@property (nonatomic) CGFloat barWidth;

@property (nonatomic) CGFloat labelMarginTop;

/** Background color of all bars in the chart. */
@property (nonatomic) UIColor * barBackgroundColor;

/** Text color for all bars in the chart. */
@property (nonatomic) UIColor * labelTextColor;

/** Font for all bars in the chart. */
@property (nonatomic) UIFont * labelFont;

/** How many labels on the x-axis to skip in between displaying labels. */
@property (nonatomic) NSInteger xLabelSkip;

/** How many labels on the y-axis to skip in between displaying labels. */
@property (nonatomic) NSInteger yLabelSum;

/** The maximum for the range of values to display on the y-axis. */
@property (nonatomic) CGFloat yMaxValue;

/** The minimum for the range of values to display on the y-axis. */
@property (nonatomic) CGFloat yMinValue;

/** Controls whether each bar should have a gradient fill. */
@property (nonatomic) UIColor *barColorGradientStart;

/** Controls whether text for x-axis be straight or rotate 45 degree. */
@property (nonatomic) BOOL rotateForXAxisText;

@property (nonatomic) NSInteger xLabelHeight;

@property (nonatomic) CGFloat xLabelXPosition;

/** Controls whether percentage shows on Bar**/
@property (nonatomic) BOOL showPercentage;



@property (nonatomic) NSMutableArray *graphLinepathArr;


@property (nonatomic, weak) id<BKChartDelegate> delegate;

@end
