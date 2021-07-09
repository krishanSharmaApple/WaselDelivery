//
//  BKPieChart.h
//  BrandKinesis
//
//  Created by [x]cube LABS on 23/08/14.
//  Copyright (c) 2014 [x]cube LABS. All rights reserved.
//


#import <UIKit/UIKit.h>

@protocol BKPieChartDataSource;
@protocol BKPieChartDelegate;

@interface BKPieChart : UIView
@property(nonatomic, weak) id<BKPieChartDataSource> dataSource;
@property(nonatomic, weak) id<BKPieChartDelegate> delegate;
@property(nonatomic, assign) CGFloat startPieAngle;
@property(nonatomic, assign) CGFloat animationSpeed;
@property(nonatomic, assign) CGPoint pieCenter;
@property(nonatomic, assign) CGFloat pieRadius;
@property(nonatomic, assign) BOOL    showLabel;
@property(nonatomic, strong) UIFont  *labelFont;
@property(nonatomic, strong) UIColor *labelColor;
@property(nonatomic, strong) UIColor *labelShadowColor;
@property(nonatomic, assign) CGFloat labelRadius;
@property(nonatomic, assign) CGFloat selectedSliceStroke;
@property(nonatomic, assign) CGFloat selectedSliceOffsetRadius;
@property(nonatomic, assign) BOOL    showPercentage;
@property(nonatomic, assign) BOOL    showGrades;
@property (nonatomic, strong) NSArray  *grades;

- (id)initWithFrame:(CGRect)frame Center:(CGPoint)center Radius:(CGFloat)radius;
- (void)reloadData;
- (void)setPieBackgroundColor:(UIColor *)color;

- (void)setSliceSelectedAtIndex:(NSInteger)index;
- (void)setSliceDeselectedAtIndex:(NSInteger)index;

@end;


@protocol BKPieChartDataSource <NSObject>
@required
- (NSUInteger)numberOfSlicesInPieChart:(BKPieChart *)pieChart;
- (CGFloat)pieChart:(BKPieChart *)pieChart valueForSliceAtIndex:(NSUInteger)index;
@optional
- (UIColor *)pieChart:(BKPieChart *)pieChart colorForSliceAtIndex:(NSUInteger)index;
- (NSString *)pieChart:(BKPieChart *)pieChart textForSliceAtIndex:(NSUInteger)index;
@end

@protocol BKPieChartDelegate <NSObject>
@optional
- (void)pieChart:(BKPieChart *)pieChart willSelectSliceAtIndex:(NSUInteger)index;
- (void)pieChart:(BKPieChart *)pieChart didSelectSliceAtIndex:(NSUInteger)index;
- (void)pieChart:(BKPieChart *)pieChart willDeselectSliceAtIndex:(NSUInteger)index;
- (void)pieChart:(BKPieChart *)pieChart didDeselectSliceAtIndex:(NSUInteger)index;
@end
