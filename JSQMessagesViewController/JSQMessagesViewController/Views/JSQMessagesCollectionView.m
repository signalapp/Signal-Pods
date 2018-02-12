//
//  Created by Jesse Squires
//  http://www.jessesquires.com
//
//
//  Documentation
//  http://cocoadocs.org/docsets/JSQMessagesViewController
//
//
//  GitHub
//  https://github.com/jessesquires/JSQMessagesViewController
//
//
//  License
//  Copyright (c) 2014 Jesse Squires
//  Released under an MIT license: http://opensource.org/licenses/MIT
//

#import "JSQMessagesCollectionView.h"

#import "JSQMessagesCollectionViewFlowLayout.h"
#import "JSQMessagesCollectionViewCellIncoming.h"
#import "JSQMessagesCollectionViewCellOutgoing.h"

#import "JSQMessagesTypingIndicatorFooterView.h"
#import "JSQMessagesLoadEarlierHeaderView.h"

#import "UIColor+JSQMessages.h"


@interface JSQMessagesCollectionView () <JSQMessagesLoadEarlierHeaderViewDelegate>

- (void)jsq_configureCollectionView;

@end


@implementation JSQMessagesCollectionView

- (void)setFrame:(CGRect)frame {
    BOOL isChanging = !CGSizeEqualToSize(frame.size, self.frame.size);
    if (isChanging) {
        [self.layoutDelegate jsqWillChangeLayout];
    }
    [super setFrame:frame];
    if (isChanging) {
        [self.layoutDelegate jsqDidChangeLayout];
    }
}

- (void)setBounds:(CGRect)bounds {
    BOOL isChanging = !CGSizeEqualToSize(bounds.size, self.bounds.size);
    if (isChanging) {
        [self.layoutDelegate jsqWillChangeLayout];
    }
    [super setBounds:bounds];
    if (isChanging) {
        [self.layoutDelegate jsqDidChangeLayout];
    }
}

- (void)setContentOffset:(CGPoint)contentOffset {
    if (self.contentSize.height < 1 &&
        CGPointEqualToPoint(CGPointZero, contentOffset)) {
        // [UIScrollView _adjustContentOffsetIfNecessary] resets the content
        // offset to zero under a number of undocumented conditions.  We don't
        // want this behavior; we want fine-grained control over the default
        // scroll state of the message view.
        //
        // [UIScrollView _adjustContentOffsetIfNecessary] is called in
        // response to many different events; trying to prevent them all is
        // whack-a-mole.
        //
        // It's not safe to override [UIScrollView _adjustContentOffsetIfNecessary],
        // since its a private API.
        //
        // We can avoid the issue by simply ignoring attempt to reset the content
        // offset to zero before the collection view has determined its content size.
        return;
    }

    [super setContentOffset:contentOffset];
}

@dynamic dataSource;
@dynamic delegate;
@dynamic collectionViewLayout;

#pragma mark - Initialization

- (void)jsq_configureCollectionView
{
    [self setTranslatesAutoresizingMaskIntoConstraints:NO];

    self.backgroundColor = [UIColor whiteColor];
    self.keyboardDismissMode = UIScrollViewKeyboardDismissModeNone;
    self.alwaysBounceVertical = YES;
    self.bounces = YES;
    
    [self registerNib:[JSQMessagesCollectionViewCellIncoming nib]
          forCellWithReuseIdentifier:[JSQMessagesCollectionViewCellIncoming cellReuseIdentifier]];
    
    [self registerNib:[JSQMessagesCollectionViewCellOutgoing nib]
          forCellWithReuseIdentifier:[JSQMessagesCollectionViewCellOutgoing cellReuseIdentifier]];
    
    [self registerNib:[JSQMessagesCollectionViewCellIncoming nib]
          forCellWithReuseIdentifier:[JSQMessagesCollectionViewCellIncoming mediaCellReuseIdentifier]];
    
    [self registerNib:[JSQMessagesCollectionViewCellOutgoing nib]
          forCellWithReuseIdentifier:[JSQMessagesCollectionViewCellOutgoing mediaCellReuseIdentifier]];
    
    [self registerNib:[JSQMessagesTypingIndicatorFooterView nib]
          forSupplementaryViewOfKind:UICollectionElementKindSectionFooter
          withReuseIdentifier:[JSQMessagesTypingIndicatorFooterView footerReuseIdentifier]];
    
    [self registerNib:[JSQMessagesLoadEarlierHeaderView nib]
          forSupplementaryViewOfKind:UICollectionElementKindSectionHeader
          withReuseIdentifier:[JSQMessagesLoadEarlierHeaderView headerReuseIdentifier]];

    _typingIndicatorDisplaysOnLeft = YES;
    _typingIndicatorMessageBubbleColor = [UIColor jsq_messageBubbleLightGrayColor];
    _typingIndicatorEllipsisColor = [_typingIndicatorMessageBubbleColor jsq_colorByDarkeningColorWithValue:0.3f];

    _loadEarlierMessagesHeaderTextColor = [UIColor jsq_messageBubbleBlueColor];
}

- (instancetype)initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
    self = [super initWithFrame:frame collectionViewLayout:layout];
    if (self) {
        [self jsq_configureCollectionView];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self jsq_configureCollectionView];
}

#pragma mark - Typing indicator

- (JSQMessagesTypingIndicatorFooterView *)dequeueTypingIndicatorFooterViewForIndexPath:(NSIndexPath *)indexPath
{
    JSQMessagesTypingIndicatorFooterView *footerView = [super dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionFooter
                                                                                 withReuseIdentifier:[JSQMessagesTypingIndicatorFooterView footerReuseIdentifier]
                                                                                        forIndexPath:indexPath];

    [footerView configureWithEllipsisColor:self.typingIndicatorEllipsisColor
                        messageBubbleColor:self.typingIndicatorMessageBubbleColor
                       shouldDisplayOnLeft:self.typingIndicatorDisplaysOnLeft
                         forCollectionView:self];

    return footerView;
}

#pragma mark - Load earlier messages header

- (JSQMessagesLoadEarlierHeaderView *)dequeueLoadEarlierMessagesViewHeaderForIndexPath:(NSIndexPath *)indexPath
{
    JSQMessagesLoadEarlierHeaderView *headerView = [super dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader
                                                                             withReuseIdentifier:[JSQMessagesLoadEarlierHeaderView headerReuseIdentifier]
                                                                                    forIndexPath:indexPath];

    headerView.loadButton.tintColor = self.loadEarlierMessagesHeaderTextColor;
    headerView.delegate = self;

    return headerView;
}

#pragma mark - Load earlier messages header delegate

- (void)headerView:(JSQMessagesLoadEarlierHeaderView *)headerView didPressLoadButton:(UIButton *)sender
{
    if ([self.delegate respondsToSelector:@selector(collectionView:header:didTapLoadEarlierMessagesButton:)]) {
        [self.delegate collectionView:self header:headerView didTapLoadEarlierMessagesButton:sender];
    }
}

#pragma mark - Messages collection view cell delegate

- (void)messagesCollectionViewCellDidTapAvatar:(JSQMessagesCollectionViewCell *)cell
{
    NSIndexPath *indexPath = [self indexPathForCell:cell];
    if (indexPath == nil) {
        return;
    }

    [self.delegate collectionView:self
            didTapAvatarImageView:cell.avatarImageView
                      atIndexPath:indexPath];
}

- (void)messagesCollectionViewCellDidTapMessageBubble:(JSQMessagesCollectionViewCell *)cell
{
    NSIndexPath *indexPath = [self indexPathForCell:cell];
    if (indexPath == nil) {
        return;
    }

    [self.delegate collectionView:self didTapMessageBubbleAtIndexPath:indexPath];
}

- (void)messagesCollectionViewCellDidTapCell:(JSQMessagesCollectionViewCell *)cell atPosition:(CGPoint)position
{
    NSIndexPath *indexPath = [self indexPathForCell:cell];
    if (indexPath == nil) {
        return;
    }

    [self.delegate collectionView:self
            didTapCellAtIndexPath:indexPath
                    touchLocation:position];
}

- (void)messagesCollectionViewCell:(JSQMessagesCollectionViewCell *)cell didPerformAction:(SEL)action withSender:(id)sender
{
    NSIndexPath *indexPath = [self indexPathForCell:cell];
    if (indexPath == nil) {
        return;
    }

    [self.delegate collectionView:self
                    performAction:action
               forItemAtIndexPath:indexPath
                       withSender:sender];
}

@end
