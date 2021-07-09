//
//  BKPreferences.h
//  BrandKinesis
//
//  Created by [x]cube LABS on 09/10/14.
//  Copyright (c) 2014 [x]cube LABS. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Upshot/BrandKinesis.h>
#import <Upshot/BKBGColor.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, BKActivityButtonType) {
    /*!
     Next button in Survey And Trivia view
     */
    BKActivityNextButton,
    /*!
     Previous button in Survey And Trivia view
     */
    BKActivityPreviousButton,
    /*!
     Continue button in Survey And Trivia view
     */
    BKActivityContinueButton,
    //Rating
    /*!
     Like Button in ratings view
     */
    BKActivityRatingLikeButton,
    /*!
     Dislike Button in ratings view
     */
    BKActivityRatingDislikeButton,
    /*!
     Submit Button in Rating And Opinion Poll view
     */
    BKActivitySubmitButton,
    /*!
     Rating Redirection YES button in Rating View
     */
    BKActivityRatingYesButton,
    /*!
     Rating Redirection NO button in Rating View
     */
    BKActivityRatingNoButton,
    /*!
     Activity Skip button for All Actions
     */
    BKActivitySkipButton,
    
};

typedef NS_ENUM (NSInteger, BKActivityLabelType) {
    /*!
     Label For question in Survey, Rating, Opinion_poll And Trivia view
     */
    BKActivityQuestionLabel,
    /*!
     Label For opiton in Survey, Opinion_poll And Trivia view
     */
    BKActivityOptionLabel,

    /*!
     Label For seperator in opitons in Survey, Opinion_poll And Trivia view
     */
    BKActivitySeparatorLabel,

    /*!
     Label For description in Survey And Trivia view
     */
    BKActivityDescriptionLabel,
    
    /*!
     Lable for Thankyou for Surevy, Rating And Opinion_poll view
     */
    BKActivityThankyouLabel,
    
    /*!
     Label for Activity header in Survey, Rating And Trivia
     */
    BKActivityHeaderLabel,

    /*!
     Label for Activity Legend in opinion_poll And Trivia view
     */
    BKActivityLegendLabel,

    /*!
     Label for Activity Legend in Rating view
     */
    BKActivityThankyouAppStoreHint,
    
    /*!
     Label for Activity for Tutorial Not using currently
     */
    BKActivityLabelTypeTutorialBottomText,
    
    /*!
     Label for Activity Slider Score in Survey And Rating view
     */
    BKActivitySliderScoreLabel,
    
    /*!
     Label for Activity SliderMinValueLabel in Survey And Rating view
     */
    BKActivitySliderMinValueLabel,
    
    /*!
     Label for Activity SliderMaxValueLabel in Survey And Rating view
     */
    BKActivitySliderMaxValueLabel,
    
    /*!
     Label for Activity MinValueTitleLabel in Survey And Rating view
     */
    BKActivityMinValueTitleLabel,
    
    /*!
     Label for Activity MaxValueTitleLabel in Survey And Rating view
     */
    BKActivityMaxValueTitleLabel,
    
    /*!
     Label for Activity YourGrade in Trivia view
     */
    BKActivityYourGradeLabel,
    
    /*!
     Label for Activity YourScore in Trivia view
     */
    BKActivityYourScoreLabel,
    
    /*!
     Label for Activity Score in Trivia view
     */
    BKActivityScoreLabel,
    
    /*!
     Label for Activity UserScore in Trivia view
     */
    BKActivityUserScoreLabel,
    
    /*!
     Label for Activity UserGrade in Trivia view
     */
    BKActivityUserGradeLabel,
    
    /*!
     Label for Activity BarGraphUserLabel in Opinion_poll And Trivia view
     */
    BKActivityBarGraphUserLabel,
    
    /*!
     Label for Activity BarGraphOptionsLabel in Opinion_poll And Trivia view
     */
    BKActivityBarGraphOptionsLabel,
    
    /*!
     Label for Activity TriviaResults in Trivia view
     */
    BKActivityTriviaResultsLabel,
    
    /*!
     Label for Activity TriviaResults in Trivia view
     */
    BKActivityTriviaTabularResponsesLabel,
    
    /*!
     Label for Activity TriviaResults in Trivia view
     */
    BKActivityTriviaTabularGradeLabel,
};

/*!
 @brief  All Images Preferences
 */
typedef NS_ENUM(NSInteger, BKActivityImageType){
    /*!
     @brief  Header Logo in landScapeMode for Survey, Rating, Opinion_Poll and Trivia view
     */
    BKActivityLandscapeLogo,

    /*!
     @brief  Header Logo in PortraitMode for Survey, Rating, Opinion_Poll and Trivia view
     */
    BKActivityPortraitLogo,
 
    /*!
     @brief Survey Check Box Image for Survey and Trivia view
     */
    BKActivityCheckboxImage,
    /*!
     @brief  All Radio Images for Survey, Opinion_Poll and Trivia view
     */
    BKActivityRadioImage,

    /*!
     @brief  Backgroud Image for Survey, Rating, Opinion_Poll and Trivia view
     */
    BKActivityBackgroundImage,

    /*!
     @brief Default image if there are no Ads
     */
    BKActivityAdsDefaultImage,
};


typedef NS_ENUM(NSInteger, BKActivityRatingType) {
    /*!
     Rating for star and smiley icons in Survey And Rating view
    */
    BKActivityStarRating,
    BKActivityEmojiRating,
};

typedef NS_ENUM(NSInteger, BKGraphType){
    
    /*!
     Poll And Trivia Graph
     */
    BKActivityBarGraph,
    BKActivityPieGraph,
    
};

typedef NS_ENUM(NSInteger, BKActivityConstraintType) {
    
    BKActivityBottomPageControlConstraint,
    
    BKActivityBottomSectionViewControlConstraint,
    
};

typedef NS_ENUM(NSInteger, BKActivityViewType){
    
    BKActivityFreeFormText,
    BKActivityCommentField
};

typedef NS_ENUM(NSInteger, BKActivityColorType) {
    /*!
     Background color
     */
    BKActivityBGColor,

    /*!
     Background color for Header
     */
    BKActivityHeaderBGColor,
    
    /*!
     Background color for Bottom
     */
    BKActivityBottomBGColor,
    
    /*!
     Stroke color for Graph
     */
    BKActivityStrokeColor,

    /*!
    Color for Graph
     */
    BKActivityGraphLabelColor,
    
    /*!
    PageTintColor for Survey view
     */
    BKActivityPageTintColor,
    
    /*!
    AnsweredPageTintColor for Survey
     */
    BKActivityAnsweredPageTintColor,
    
    /*!
    CurrentPageTintColor for Survey,
     */
    BKActivityCurrentPageTintColor,
    
    /*!
     PercentageColor for Opinion_poll And Trivia
     */
    BKActivityPercentageColor,
    
    BKActivityNPSUnSelectedBGColor,
    
    BKActivityNPSSelectedBGColor,
    
    BKActivityNPSSelectedTextColor,
    
    BKActivityNPSUnSelectedTextColor,
    
    BKActivityNPSDefaultBorderColor,
    
    BKActivityNPSSelectedBorderColor,
    
    BKActivityOptionDefaultBorderColor,
    BKActivityOptionSelectedBorderColor,

};


@protocol BKUIPreferencesDelegate;


@interface BKUIPreferences : NSObject{

    

}

@property (nonatomic, strong) id<BKUIPreferencesDelegate> delegate;

//Inbox Header Properties
@property (nonatomic, strong) UIImage  *inboxHeaderBackgroundImage;
@property (nonatomic, strong) UIColor  *inboxHeaderBackgroundColor;
@property (nonatomic, strong) NSString *inboxTitle;
@property (nonatomic, strong) UIFont   *inboxTitleFont;
@property (nonatomic, strong) UIColor  *inboxTitleColor;

// Inbox Cancel Button Properties
@property (nonatomic, strong) NSString *inboxCancelTitle;
@property (nonatomic, strong) UIColor  *inboxCancelTitleColor;
@property (nonatomic, strong) UIFont   *inboxCancelTitleFont;
@property (nonatomic, strong) UIImage  *inboxCancelImage;

//Inbox LoadMore button Options
@property (nonatomic, strong) UIColor  *inboxLoadmorebackgroundColor;
@property (nonatomic, strong) UIColor  *inboxLoadmoreTitleColor;
@property (nonatomic, strong) UIFont   *inboxLoadmoreTitleFont;
@property (nonatomic, strong) UIImage  *inboxLoadmorebackgroundImage;
@property (nonatomic, strong) NSString *inboxLoadmoreTitle;

// Inbox cell properties
@property (nonatomic, strong) UIFont   *inboxCellTextFont;
@property (nonatomic, strong) UIFont   *inboxCellDetailTextFont;

@property (nonatomic, strong) UIColor  *inboxCellTextColor;
@property (nonatomic, strong) UIColor  *inboxCellDetailTextColor;
@property (nonatomic, strong) UIColor  *inboxCellReadBackgroundColor;
@property (nonatomic, strong) UIColor  *inboxCellUnreadBackgroundColor;

// Inbox TableView header
@property (nonatomic, strong) UIColor  *inboxSectionHeaderTitleColor;
@property (nonatomic, strong) UIFont   *inboxSectionHeaderTitleFont;
@property (nonatomic, strong) UIColor  *inboxSectionHeaderBackgroundColor;

// Inbox Popover
/*!
 Border color will also apply to cancel Button
 */
@property (nonatomic, strong) UIColor  *inboxPopoverBorderColor;
@property (nonatomic, strong) NSString *inboxPopoverTitle;


/*!
 Background image for cancel button. With this only background image is considerd and border color is removed
 */
@property (nonatomic, strong) UIImage  *inboxPopoverCancelButtonBackgroundImage;
@property (nonatomic, strong) NSString *inboxPopoverCancelButtonTitle;
@property (nonatomic, strong) UIColor  *inboxPopoverCancelButtonTitleColor;

@property (nonatomic, assign) BOOL isFullScreen;
@property (nonatomic, assign) BOOL isFloatButton;

+ (BKUIPreferences *)preferences NS_SWIFT_NAME(preferences());
- (BKUIPreferences *)defaultInboxPreferences;

@end


@protocol BKUIPreferencesDelegate <NSObject>


@optional
/*!
 @brief  Mehtod to set custom preferences to any button based on corresponding activity and button type
 
 @param button         button
 @param activityType   {@link BKActivityType}
 @param activityButton {@link BKactivityButtonType}
 
 @since 0.9
 */
- (void)preferencesForUIButton:(UIButton *)button
                 ofActivity:(BKActivityType)activityType
                    andType:(BKActivityButtonType)activityButton;


/*!
 @brief  Mehtod to set custom preferences to any button based on corresponding activity and ImageView
 
 @param imageView     imageView
 @param activityType  {@link BKActivityType}
 @param activityImage {@link BKActivityImageType}
 
 @since 0.9
 */
- (void)preferencesForUIImageView:(UIImageView *)imageView
                    ofActivity:(BKActivityType)activityType
                       andType:(BKActivityImageType)activityImage;
/*!
 @brief  Mehtod to set custom preferences to any button based on corresponding activity and Label
 
 @param label         label
 @param activityType  {@link BKActivityType}
 @param activityLabel {@link BKActivityLabelType}
 
 @since 0.9
 */
- (void)preferencesForUILabel:(UILabel *)label
                       ofActivity:(BKActivityType)activityType
                       andType:(BKActivityLabelType)activityLabel;

/*!
 @brief  Mehtod to set custom preferences to any button based on corresponding activity and Rating
 
 @param activityType    {@link BKActivityType}
 @param activityRating  {@link BKActivityRatingType}
 @param block           This requires Default images and selected images
 
 @since 0.9
 */
- (void)preferencesForRatingActivity:(BKActivityType)activityType
                     andType:(BKActivityRatingType)activityRating
                  withImages:(void(^)(NSArray *defaultImages, NSArray *selectedImages))block;


- (void)preferencesForGraphColor:(BKGraphType)graphType graphColors:(void(^)(NSArray *colors))block;

/*!
 @brief  Mehtod to set custom preferences to any button based on corresponding activity and Rating
 
 @param color         color
 @param activityType  {@link BKActivityType}
 @param activityColor {@link BKActivityColorType}
 
 @since 0.9
 */
- (void)preferencesForUIColor:(BKBGColor *)color
                   ofActivity:(BKActivityType)activityType
                      colorType:(BKActivityColorType)activityColor
              andButtonType:(BOOL)isFloatButton;


/*!
 @brief  Mehtod to set custom preferences to any button based on corresponding activity and Tutorial
 
 @param constraint         constraint
 @param activityType  {@link BKActivityType}
 @param activityColor {@link BKActivityColorType}
 
 @since 0.9
 */

- (void)preferencesForConstraint:(NSLayoutConstraint *)constraint
                   ofActivity:(BKActivityType)activityType
                      andType:(BKActivityConstraintType)constraintType;


- (void)preferencesForSlider:(UISlider *)slider
                       ofActivity:(BKActivityType)activityType;


/*!
 @brief  Mehtod to set custom preferences to Corner Radius based on corresponding activity and Type
 
 @param activityType  {@link BKActivityType}
 
 @since 0.9
 */

- (CGFloat)preferencesForCornerRadiustoActivity:(BKActivityType)activityType;


- (void)preferencesForTextView:(UITextView *)textView
                      ofActivity:(BKActivityType)activityType
                         andType:(BKActivityViewType)viewType;

- (void)preferencesForTextField:(UITextField *)textField
                ofActivity:(BKActivityType)activityType
                   andType:(BKActivityViewType)viewType;

@end








