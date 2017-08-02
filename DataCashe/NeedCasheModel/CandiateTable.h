//
//  CandiateTable.h
//  iOS-HR
//
//  Created by peter on 16/5/12.
//  Copyright © 2016年 headhunter-HR. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CandiateTable : NSObject

@property (nonatomic, strong) NSNumber* candidateGender;/**<候选人性别*/
@property (nonatomic, assign) int statusId; //新推荐0, 待处理1
@property (nonatomic, assign) long candidateId;    //候选人id
@property (nonatomic, assign) int candidateStatus;    //候选人面试状态,具体看枚举HRCandidateProgressType
@property (nonatomic, strong) NSString *candidateAvatar;    //候选人头像
@property (nonatomic, strong) NSString *retransmitMess;    //候选人小头像
@property (nonatomic, strong) NSString *candidateSmallAvatar;    //候选人小头像
@property (nonatomic, strong) NSString *candidateName;  //候选人姓名
@property (nonatomic, assign) BOOL standardized;   //是否标准化过 0.未标准化 1.标准化
@property (nonatomic, assign) long startWorkYear;  //候选人开始工作年
@property (nonatomic, assign) long candidateDegreeId;  //候选人学历id
@property (nonatomic, assign) double candidateRecommendTime; //候选人推荐时间
@property (nonatomic, assign) long positionId; //职位id
@property (nonatomic, strong) NSString *positionName;   //职位名称
@property (nonatomic, assign) double dynamicTime;    //候选状态时间
@property (nonatomic, assign) long companyId;  //当前公司id
@property (nonatomic, strong) NSString *companyName;    //当前公司名称
@property (nonatomic, assign) BOOL isNewRecommandResume;   //是否是新推荐的,没查看过的
@property (nonatomic, assign) BOOL isUrgentPosition;   //是否是紧急职位
@property (nonatomic, strong) NSNumber *hrFeedbackHours;    //hr承诺反馈小时数
@property (nonatomic, strong) NSNumber *priorityHours;  //承诺反馈时间
@property (nonatomic, strong) NSString *resumeUrl;  //转发简历连接
@property (nonatomic, assign) double hrReadTime; //候选人详情首次查看时间
@property (nonatomic, strong) NSNumber *guaranteeMonths;    //试用期 Long类型
@property (nonatomic, strong) NSNumber *hhId;   //猎头id
@property (nonatomic, strong) NSString *hhDisplayName;  //猎头显示名字
@property (nonatomic, strong) NSString *hhPhone;    //猎头手机号
@property (nonatomic, strong) NSString *hhEmail;    //猎头猎头邮箱
@property (nonatomic, assign) BOOL hhIsMobileUser; //是否是手机用户
@property (nonatomic, strong) NSString *candidatePhone; //候选人手机号
@property (nonatomic, strong) NSString *candidateEmail; //候选人邮箱
@property (nonatomic, strong) NSString *arrangeInterviewTime;   //面试待确认时间
@property (nonatomic, assign) double lastUpdateTime;
@property (nonatomic, assign) long userId;


@end
