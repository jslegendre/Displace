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

#ifndef IOCall_hpp
#define IOCall_hpp

#include <stdexcept>
#include <optional>
#include <IOKit/IOKitLib.h>

class IOCall {
public:
  /*! @function IOCall
      @abstract Set up and empty IOCall object to be filled in later */
  IOCall() {};
  
  /*! @function IOCall
      @abstract Construct IOCall with every variable needed to start
      @param serviceMatching String for IOServiceMatching call. I.E. service you wish to poll
      @param selectorIndex Index of the service's IOKit external method to call
      @param inStruct Caller allocated buffer for IOConnectCallX input
      @param outStruct Caller allocated buffer for IOConnectCallX output
      @param inStructSize Size of inStruct
      @param outStructSize Size of outStruct */
  IOCall( const char * serviceMatching, int selectorIndex, void * inStruct, void * outStruct, size_t inStructSize, size_t outStructSize );
  
  /*! @function  ~IOCall
      @abstract Destructor. Will release services itorator, attached device,
                and close the IOConnection to attached device. */
  ~IOCall();
  
  /*! @function IOCall::call
      @abstract Perform IOConnectCallStructMethod with all variables as is */
  kern_return_t call();
  
  /*! @function IOCall::call
      @abstract Perform IOConnectCallStructMethod changing in and out args
      @param inStruct Caller allocated buffer for IOConnectCallX input
      @param outStruct Caller allocated buffer for IOConnectCallX output */
  kern_return_t call(void * inStruct, void * outStruct);
  
  /*! @function IOCall::call
      @abstract Perform IOConnectCallStructMethod changing in and out args
                and updating the size of aformentioned args
      @param inStruct Caller allocated buffer for IOConnectCallX input
      @param outStruct Caller allocated buffer for IOConnectCallX output
      @param inStructSize Size of inStruct
      @param outStructSize Size of outStruct */
  kern_return_t call(void * inStruct, void * outStruct, size_t inStructSize, size_t outStructSize);
  
  void setInStruct(void * inStruct);
  void * getInStruct();
  
  void setSelectorIndex();
  int getSelectorIndex();
  
  void setOutStruct(void * outStruct);
  void * getOutStruct();
  
  void setInStructSize(size_t size);
  size_t getInstructSize();
  
  void setOutStructSize(size_t size);
  size_t getOutStructSize();
  
  void setDevice(io_service_t device);
  io_service_t getDevice();
  
  /*! @function IOCall::nextDevice
      @abstract IOCall default behavior is to use the first device from NSDictionary
                returned by IOServiceMatching. Use this to iterate through the device
                dictionary and use IOCall::getDevice/IOCall::setDevice to attach to
                the non-default device. */
  void nextDevice();
  
protected:
  int selectorIndex;
  void * inStruct;
  void * outStruct;
  size_t inStructSize;
  size_t outStructSize;
private:
  io_connect_t connection;
  io_service_t device;
  io_iterator_t services;
};

#endif /* IOCall_hpp */
