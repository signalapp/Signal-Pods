#import "UFDisjointSetNode.h"

@implementation UFDisjointSetNode {
@private UFDisjointSetNode* _parent;
@private uint32_t _rank;
}

-(id)init {
    self = [super init];
    if (self == nil) return nil;

    _parent = self;
    return self;
}

-(UFDisjointSetNode *)currentRepresentative {
    if (_parent != self) {
        _parent = _parent.currentRepresentative;
    }
    return _parent;
}

-(bool)unionWith:(UFDisjointSetNode *)other {
    NSCParameterAssert(other != nil);
    
    UFDisjointSetNode* rep1 = self.currentRepresentative;
    UFDisjointSetNode* rep2 = other.currentRepresentative;
    if (rep1 == rep2) return false;

    if (rep1->_rank < rep2->_rank) {
        rep1->_parent = rep2->_parent;
    } else if (rep1->_rank > rep2->_rank) {
        rep2->_parent = rep1->_parent;
    } else {
        rep2->_parent = rep1->_parent;
        rep1->_rank++;
    }
    return true;
}

-(bool)isInSameSetAs:(UFDisjointSetNode *)other {
    NSCParameterAssert(other != nil);
    
    return self.currentRepresentative == other.currentRepresentative;
}

@end
