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

#include "IOCall.hpp"

IOCall::IOCall(const char * serviceMatching, int selectorIndex, void * inStruct, void * outStruct,
               size_t inStructSize, size_t outStructSize)
: selectorIndex(selectorIndex), inStruct(inStruct), outStruct(outStruct),
inStructSize(inStructSize), outStructSize(outStructSize)
{
  CFMutableDictionaryRef dict = IOServiceMatching(serviceMatching);
  if(!dict) {
    throw std::invalid_argument("IOServiceMatching returned no matching services");
  };
  
  if(IOServiceGetMatchingServices(kIOMasterPortDefault, dict, &services)!= KERN_SUCCESS) {
    throw std::invalid_argument("IOServiceGetMatchingServices could not find IOService objects currently registered by IOKit");
  };
  
  device = IOIteratorNext(services);
  if(!device){
    throw std::invalid_argument( "No services found" );
  };
  
  if(IOServiceOpen(device, mach_task_self(), 0, &connection) != KERN_SUCCESS) {
    throw std::invalid_argument("Could not open connection to service");
  };
}

IOCall::~IOCall()
{
  if(services)
    IOObjectRelease(services);
  
  if(device)
    IOObjectRelease(device);
  
  if(connection)
    IOServiceClose(connection);
}

kern_return_t IOCall::call()
{
  kern_return_t ret = IOConnectCallStructMethod(connection,
                                                selectorIndex,
                                                (const void *)inStruct,
                                                inStructSize,
                                                outStruct,
                                                &outStructSize);
  if(ret != kIOReturnSuccess) {
    printf("IOCall::call->IOConnectCallStruct method returned error code: %d\n", err_get_code(ret));
    throw std::invalid_argument("IOConnectCallStructMethod did not return kIOReturnSuccess");
  }
  return ret;
}


kern_return_t IOCall::call(void * inStruct,
                           void * outStruct)
{
  if(inStruct)
    this->inStruct = inStruct;
  
  if(outStruct)
    this->outStruct = outStruct;
  
  return call();
}

kern_return_t IOCall::call(void * inStruct,
                           void * outStruct,
                           size_t inStructSize,
                           size_t outStructSize)
{
  this->inStructSize = inStructSize;
  this->outStructSize = outStructSize;
  
  return call(inStruct, outStruct);
}

void IOCall::setInStruct(void * inStruct)
{
  this->inStruct = inStruct;
}

void * IOCall::getInStruct()
{
  return inStruct;
}

void IOCall::setOutStruct(void * outStruct)
{
  this->outStruct = outStruct;
}

void * IOCall::getOutStruct()
{
  return outStruct;
}

void IOCall::setInStructSize(size_t size)
{
  this->inStructSize = size;
}

size_t IOCall::getInstructSize()
{
  return inStructSize;
}

void IOCall::setOutStructSize(size_t size)
{
  this->outStructSize = size;
}

size_t IOCall::getOutStructSize()
{
  return outStructSize;
}

void IOCall::setDevice(io_service_t device)
{
  this->device = device;
}

io_service_t IOCall::getDevice()
{
  return device;
}

void IOCall::nextDevice()
{
  device = IOIteratorNext(services);
}
