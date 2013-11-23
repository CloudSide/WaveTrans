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
    q->last = length-1;
    q->count = 0;
    q->length = length;
}

void enqueue_adv(queue *q, queue_item x)
{
    queue_item xx = x;
    
    if (!queue_is_empty(q)) {
        
        xx = x * 0.5 + q->q[q->last] * 0.5;
        
        if (xx <= x) {
            
            xx = x;
        }
        
        if (xx < 0.05) {
            
            xx = (queue_item)0.0;
        }
        
        /*
        
        if (q->q[q->last] >= xx) {
            
            xx = (queue_item)0.0;
        
        } else {
        
            q->q[q->last] = (queue_item)0.0;
        }
        
        if (xx < 0.05) {
            
            xx = (queue_item)0.0;
        }
         */
    }
    
    enqueue(q, xx);
}

void enqueue(queue *q, queue_item x)
{
    if (q->count >= q->length)
		dequeue(q);
    //else
    {
        q->last = (q->last+1) % q->length;
        q->q[ q->last ] = x;
        q->count = q->count + 1;
    }
}

queue_item dequeue(queue *q)
{
    queue_item x;
    
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

queue_item queue_item_at_index(queue *q, int index)
{
    int i = q->first;
    
    if (index > 0) {
        
        i = (i + index) % q->length;
    }
    
    return q->q[i];
}

void print_queue(queue *q)
{
    int i;
    
    i = q->first;
    
    while (i != q->last) {
        
        printf("%f ",q->q[i]);
        i = (i+1) % q->length;
    }
    
    printf("%f ",q->q[i]);
    printf("\n");
}