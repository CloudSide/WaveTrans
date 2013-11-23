//
//  queue.h
//  aurioTouch2
//
//  Created by Bruce on 13-11-6.
//
//

#ifndef aurioTouch2_queue_h
#define aurioTouch2_queue_h


#define QUEUESIZE       128

typedef float queue_item;

typedef struct {
    
    queue_item q[QUEUESIZE+1] = {0};		/* body of queue */
    int first;                              /* position of first element */
    int last;                               /* position of last element */
    int count;                              /* number of queue elements */
    int length;

} queue;

void init_queue(queue *q, int length);
void enqueue(queue *q, queue_item x);
void enqueue_adv(queue *q, queue_item x);
queue_item dequeue(queue *q);
int queue_is_empty(queue *q);
void print_queue(queue *q);
queue_item queue_item_at_index(queue *q, int index);

#endif
