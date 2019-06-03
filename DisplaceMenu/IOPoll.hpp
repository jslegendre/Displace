/*
 * Copyright (c) 2019 jslegendre / Xord. All rights reserved.
 *
 *  Released under "The GNU General Public License (GPL-2.0)"
 *
 *  This program is free software; you can redistribute it and/or modify it
 *  under the terms of the GNU General Public License as published by the
 *  Free Software Foundation; either version 2 of the License, or (at your
 *  option) any later version.
 *
 *  This program is distributed in the hope that it will be useful, but
 *  WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
 *  or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License
 *  for more details.
 *
 *  You should have received a copy of the GNU General Public License along
 *  with this program; if not, write to the Free Software Foundation, Inc.,
 *  59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 *
 */

#ifndef IOPoll_hpp
#define IOPoll_hpp

#include <objc/objc-runtime.h>
#include "IOCall.hpp"

class IOPoll : IOCall {
public:
  /*! @function IOPoll
      @abstract Default (empty) constructor */
  IOPoll() {};
  
  /*! @function IOPoll
      @abstract Constructor setting polling interval and result handler
      @param interval Polling interval in seconds
      @param resultHandler Function pointer to call after each poll */
  IOPoll(double interval, void (*resultHandler)(void));
  
  /*! @function IOPoll
      @abstract Constructor setting premade IOCall instance, polling interval
                and result handler
      @param ioCall Premade IOCall instance
      @param interval Polling interval in seconds
      @param resultHandler Function pointer to call after each poll */
  IOPoll(IOCall *ioCall, double interval, void (*resultHandler)(void));
  
  /*! @function IOPoll
      @abstract Constructor setting all IOCall member variables, polling interval
                and result handler
      @param serviceMatching String for IOServiceMatching call. I.E. service you wish to poll
      @param selectorIndex Index of the service's IOKit external method to call
      @param inStruct Caller allocated buffer for IOConnectCallX input
      @param outStruct Caller allocated buffer for IOConnectCallX output
      @param inStructSize Size of inStruct
      @param outStructSize Size of outStruct
      @param interval Polling interval in seconds
      @param resultHandler Function pointer to call after each poll */
  IOPoll(const char * serviceMatching, int selectorIndex, void * inStruct, void * outStruct,
         size_t inStructSize, size_t outStructSize, double interval, void (*resultHandler)(void));
  
  /*! @function ~IOPoll
      @abstract Destructor. Will stop polling and call IOCall destructor. */
  ~IOPoll();
  void start();
  void stop();
  
  void setInterval(int interval);
  int getInterval();
  
  void setPolling(bool polling);
  bool getPolling();
  
  void setResultHandler(void (*resultHandler)());
  void (*getResultHandler(void))();
protected:
  bool pollIsRunning;
  void poll();
private:
  IOCall *ioCall;
  double interval;
  bool polling;
  void (*resultHandler)(void);
};


#endif /* IOPoll_hpp */
