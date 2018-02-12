#import <Foundation/Foundation.h>

/*!
 * A UFDisjointSetNode is a member, and potential representative, of an implicit set of nodes.
 * 
 * @discussion UFDisjointSetNode sets are disjoint, meaning they never partially overlap.
 * The implicit sets either have all elements in common, or no elements in common.
 *
 * New nodes are in a new implicit set all by themselves.
 *
 * Use 'isInSameSetAs' to determine if two nodes are in the same set.
 *
 * Use 'currentRepresentative' to go from a node to the current node representing the set the original node is in.
 *
 * Use 'unionWith' to merge the sets represented by two nodes.
 *
 * The amortized cost of performing N operations on up to N nodes is very nearly O(N).
 * The actual bound is O(N inverseAckermann(N)), where inverseAckermann(N) <= 5 for all practical purposes.
 */
@interface UFDisjointSetNode : NSObject

/*!
 * Initializes the receiving node to be in a set by itself.
 */
-(instancetype)init;

/*!
 * Returns a UFDisjointSetNode representing the set the receiving node is in.
 *
 * @discussion All nodes in the same set will return the same representative.
 *
 * The representative can change when sets are combined via 'unionWith'.
 */
-(UFDisjointSetNode*)currentRepresentative;

/*!
 * Combines the set the receiving node is in with the set the given other node is in.
 *
 * @discussion If the nodes are already in the same set, nothing happens.
 *
 * Modifies the representatives of the sets.
 *
 * @return Whether or not the nodes were in separate sets.
 * True when they were in separate sets, so the operation merged the two sets.
 * False when the operation did nothing because the nodes were already in the same set.
 */
-(bool)unionWith:(UFDisjointSetNode*)other;

/*!
 * Determines if the receiving node is in the same set as the given other node.
 *
 * @discussion A node is in the same set as itself (reflexivity).
 *
 * A node is in the same set as any node it has been unioned with,
 * as well as nodes those nodes have been unioned with (transitivity).
 */
-(bool)isInSameSetAs:(UFDisjointSetNode*)other;

@end
