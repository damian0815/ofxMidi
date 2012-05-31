#include "ofxPGMidiOut.h"

#include "ofxPGMidiContext.h"

// -----------------------------------------------------------------------------
ofxPGMidiOut::ofxPGMidiOut(const string name) : ofxBaseMidiOut(name) {
	
	// setup global midi instance
	ofxPGMidiContext::setup();
	midi = ofxPGMidiContext::getMidi();
	
	destination = nil;
}

// -----------------------------------------------------------------------------
ofxPGMidiOut::~ofxPGMidiOut() {
	closePort();
}

// -----------------------------------------------------------------------------
// TODO: replace cout with ofLogNotice when OF_LOG_NOTICE is the default log level
void ofxPGMidiOut::listPorts() {
	PGMidi* midi = ofxPGMidiContext::getMidi();
	int count = [midi.destinations count]; 
	cout << "ofxMidiOut: " << count << " ports available" << endl;
	for(NSUInteger i = 0; i < count; ++i) {
			PGMidiDestination * dest = [midi.destinations objectAtIndex:i];
		cout << "ofxMidiOut: " << i << ": " << [dest.name UTF8String] << endl;
	}
}

// -----------------------------------------------------------------------------
vector<string>& ofxPGMidiOut::getPortList() {
	portList.clear();
	for(PGMidiDestination * dest in midi.destinations) {
		portList.push_back([dest.name UTF8String]);
	}
	return portList;
}

// -----------------------------------------------------------------------------
int ofxPGMidiOut::getNumPorts() {
	return [midi.destinations count];
}

// -----------------------------------------------------------------------------
string ofxPGMidiOut::getPortName(unsigned int portNumber) {
	// handle OBJ-C exceptions
	@try {
		PGMidiDestination * dest = [midi.destinations objectAtIndex:portNumber]; 
		return [dest.name UTF8String];
	}
	@catch(NSException * ex) {
		ofLog(OF_LOG_ERROR, "ofxMidiOut: couldn't get name for port %i: %s: %s",
			portNumber, ex.name, ex.reason);
	}
	return "";
}

// -----------------------------------------------------------------------------
bool ofxPGMidiOut::openPort(unsigned int portNumber) {	
	
	PGMidiDestination * dest = nil;
	
	// handle OBJ-C exceptions
	@try {
		dest = [midi.destinations objectAtIndex:portNumber]; 
	}
	@catch(NSException * ex) {
		ofLog(OF_LOG_ERROR, "ofxMidiOut: couldn't get name for port %i: %s: %s",
			portNumber, ex.name, ex.reason);
		return false;
	}
	destination = dest;
	portNum = portNumber;
	portName = [dest.name UTF8String];
	bOpen = true;
	ofLog(OF_LOG_VERBOSE, "ofxMidiOut: opened port %i %s",
		portNum, portName.c_str());
	return true;
}

// -----------------------------------------------------------------------------
bool ofxPGMidiOut::openPort(string deviceName) {
	
	// iterate through MIDI ports, find requested device
	int port = -1;
	for(NSUInteger i = 0; i < [midi.destinations count]; ++i) {
		PGMidiSource * dest = [midi.destinations objectAtIndex:i];
		if([dest.name UTF8String] == deviceName) {
			port = i;
			break;
		}
	}
	
	// bail if not found
	if(port == -1) {
		ofLog(OF_LOG_ERROR, "ofxMidiOut: port \"%s\" is not available", deviceName.c_str());
		return false;
	} 
	
	return openPort(port);
}

// -----------------------------------------------------------------------------
bool ofxPGMidiOut::openVirtualPort(string portName) {
	ofLog(OF_LOG_WARNING, "ofxMidiOut: couldn't open virtual port \"%s\"", portName.c_str());
	ofLog(OF_LOG_WARNING, "ofxMidiOut: virtual ports are currently not supported on iOS");
	return false;
}

// -----------------------------------------------------------------------------
void ofxPGMidiOut::closePort() {

	if(destination != nil) {
		ofLog(OF_LOG_VERBOSE, "ofxMidiOut: closing port %i %s", portNum, portName.c_str());
	}
	destination = nil;
	
	portNum = -1;
	portName = "";
	bOpen = false;
	bVirtual = false;
}

// PRIVATE
// -----------------------------------------------------------------------------
// adapted from PGMidi sendBytes
void ofxPGMidiOut::sendMessage() {

    Byte packetBuffer[message.size()+100];
    MIDIPacketList * packetList = (MIDIPacketList*)packetBuffer;
    MIDIPacket * packet = MIDIPacketListInit(packetList);

    packet = MIDIPacketListAdd(packetList, sizeof(packetBuffer), packet, 0, message.size(), &message[0]);

	[destination sendPacketList:packetList];
	bMsgInProgress = false;
}
