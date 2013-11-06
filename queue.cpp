//
//  queue.cpp
//  aurioTouch2
//
//  Created by Bruce on 13-11-6.
//
//

#include "queue.h"
#include <stdio.h>
#include <stdbool.h>

void init_queue(queue *q, int length)
{
    if (length >= QUEUESIZE)
		printf("Warning: queue overflow enqueue x=%d\n", length);
    
    q->first = 0;
    q->last = QUEUESIZE-1;
    q->count = 0;
    q->length = length;
}

void enqueue(queue *q, queue_item x)
{
    if (q->count >= q->length)
		dequeue(q);
    else {
        q->last = (q->last+1) % q->length;
        q->q[ q->last ] = x;
        q->count = q->count + 1;
    }
}

queue_item dequeue(queue *q)
{
    int x;
    
    if (q->count <= 0) printf("Warning: empty queue dequeue.\n");
    else {
        x = q->q[ q->first ];
        q->first = (q->first+1) % q->length;
        q->count = q->count - 1;
    }
    
    return(x);
}

int queue_is_empty(queue *q)
{
    if (q->count <= 0) return (true);
    else return (false);
}