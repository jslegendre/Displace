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

#include "IOPoll.hpp"

IOPoll::IOPoll( double interval, void (*resultHandler)(void))
:interval(interval), polling(false), resultHandler(resultHandler)
{}

IOPoll::IOPoll(const char * serviceMatching, int selectorIndex, void * inStruct, void * outStruct,
               size_t inStructSize, size_t outStructSize, double interval, void (*resultHandler)(void))
: IOCall(serviceMatching, selectorIndex, inStruct, outStruct, inStructSize, outStructSize),
interval(interval), polling(false), resultHandler(resultHandler)
{}

IOPoll::IOPoll(IOCall *ioCall, double interval, void (*resultHandler)(void))
:ioCall(ioCall), interval(interval), polling(false), resultHandler(resultHandler)
{}

IOPoll::~IOPoll()
{
  stop();
  IOCall::~IOCall();
}

void IOPoll::poll()
{
  kern_return_t ret = kIOReturnSuccess;
  while(polling) {
    try {
      ret = IOCall::call();
    } catch(std::exception & e) {
      printf("IOPoll::poll caught IOCall::call\n");
      std::rethrow_exception(std::current_exception());
    }
    try {
      (*resultHandler)();
    } catch(std::exception & e) {
      printf("IOPoll::poll caught resultHandler\n");
      std::rethrow_exception(std::current_exception());
    }
    usleep(interval * 1000000);
  }
}

void IOPoll::start()
{
  if(!polling) {
    polling = true;
    try {
      poll();
    } catch(std::exception & e) {
      printf("IOPoll::start caught IOPoll::poll\n");
      std::rethrow_exception(std::current_exception());
    }
  }
}

void IOPoll::stop()
{
  if(polling)
    polling = false;
}

void IOPoll::setInterval(int interval)
{
  this->interval = interval;
}

int IOPoll::getInterval()
{
  return interval;
}

void IOPoll::setPolling(bool polling)
{
  this->polling = polling;
}

bool IOPoll::getPolling()
{
  return polling;
}

void IOPoll::setResultHandler(void (*resultHandler)())
{
  this->resultHandler = resultHandler;
}

void (*IOPoll::getResultHandler(void))()
{
  return resultHandler;
}
