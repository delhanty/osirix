/*=========================================================================
  Program:   OsiriX

  Copyright (c) OsiriX Team
  All rights reserved.
  Distributed under GNU - GPL
  
  See http://homepage.mac.com/rossetantoine/osirix/copyright.html for details.

     This software is distributed WITHOUT ANY WARRANTY; without even
     the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
     PURPOSE.
=========================================================================*/

#import "DicomImage.h"
#import <OsiriX/DCM.h>
#import "DCMView.h"

#ifdef OSIRIX_VIEWER
#import "DCMPix.h"
#import "VRController.h"
#import "browserController.h"
#import "BonjourBrowser.h"
#endif

#define ROIDATABASE @"/ROIs/"

inline int charToInt( unsigned char c)
{
	switch( c)
	{
		case 0:			return 0;		break;
		case '0':		return 1;		break;
		case '1':		return 2;		break;
		case '2':		return 3;		break;
		case '3':		return 4;		break;
		case '4':		return 5;		break;
		case '5':		return 6;		break;
		case '6':		return 7;		break;
		case '7':		return 8;		break;
		case '8':		return 9;		break;
		case '9':		return 10;		break;
		case '.':		return 11;		break;
	}
	
	return 1;
}

inline unsigned char intToChar( int c)
{
	switch( c)
	{
		case 0:		return 0;		break;
		case 1:		return '0';		break;
		case 2:		return '1';		break;
		case 3:		return '2';		break;
		case 4:		return '3';		break;
		case 5:		return '4';		break;
		case 6:		return '5';		break;
		case 7:		return '6';		break;
		case 8:		return '7';		break;
		case 9:		return '8';		break;
		case 10:	return '9';		break;
		case 11:	return '.';		break;
	}
	
	return '0';
}


void* sopInstanceUIDEncode( NSString *sopuid)
{
	unsigned int	i, x;
	unsigned char	*r = malloc( 1024);
	
	for( i = 0, x = 0; i < [sopuid length];)
	{
		unsigned char c1, c2;
		
		c1 = [sopuid characterAtIndex: i];
		i++;
		if( i == [sopuid length]) c2 = 0;
		else c2 = [sopuid characterAtIndex: i];
		i++;
		
		r[ x] = (charToInt( c1) << 4) + charToInt( c2);
		x++;
	}
	
	r[ x] = 0;
	
	return r;
}

NSString* sopInstanceUIDDecode( unsigned char *r)
{
	unsigned int	i, x, length = strlen( (char *) r);
	char			str[ 1024];
	
	for( i = 0, x = 0; i < length; i++)
	{
		unsigned char c1, c2;
		
		c1 = r[ i] >> 4;
		c2 = r[ i] & 15;
		
		str[ x] = intToChar( c1);
		x++;
		str[ x] = intToChar( c2);
		x++;
	}
	
	str[ x ] = '\0';
	
	return [NSString stringWithCString:str encoding: NSASCIIStringEncoding];
}

@implementation DicomImage

- (NSArray*) SRPaths
{
	NSMutableArray	*roiFiles = [NSMutableArray array];
	int	noOfFrames = [[self valueForKey: @"numberOfFrames"] intValue], x;
	
	for( x = 0; x < noOfFrames; x++)
	{
		NSString	*roiPath = [self SRPathForFrame: x];
		
		if( [[NSFileManager defaultManager] fileExistsAtPath: roiPath])
			[roiFiles addObject: roiPath];
	}
	
	return roiFiles;
}

- (NSArray*) SRFilenames
{
	NSMutableArray	*roiFiles = [NSMutableArray array];
	int	noOfFrames = [[self valueForKey: @"numberOfFrames"] intValue], x;
	
	for( x = 0; x < noOfFrames; x++)
	{
		NSString	*roiPath = [self SRFilenameForFrame: x];
		
		if( [[NSFileManager defaultManager] fileExistsAtPath: roiPath])
			[roiFiles addObject: roiPath];
	}
	
	return roiFiles;
}

- (NSString*) SRFilenameForFrame: (int) frameNo
{
	return [NSString stringWithFormat: @"%@-%d.dcm", [self uniqueFilename], frameNo];
}

- (NSString*) SRPathForFrame: (int) frameNo
{
	#ifdef OSIRIX_VIEWER
	NSString	*documentsDirectory = [[[BrowserController currentBrowser] fixedDocumentsDirectory] stringByAppendingPathComponent:ROIDATABASE];
	
	return [documentsDirectory stringByAppendingPathComponent: [self SRFilenameForFrame: frameNo]];
	#else
	return 0L;
	#endif
}

- (NSString*) sopInstanceUID
{
	if( sopInstanceUID) return sopInstanceUID;
	
	unsigned char* src =  (unsigned char*) [[self primitiveValueForKey:@"compressedSopInstanceUID"] bytes];
	
	if( src)
	{
		NSString* uid =  sopInstanceUIDDecode( src);
		
		[sopInstanceUID release];
		sopInstanceUID = [uid retain];
	}
	else
	{
		[sopInstanceUID release];
		sopInstanceUID = 0L;
	}
	
	return sopInstanceUID;
}

- (void) setSopInstanceUID: (NSString*) s
{
	[sopInstanceUID release];
	sopInstanceUID = 0L;

	if( s)
	{
		char *ss = sopInstanceUIDEncode( s);
		[self setValue: [NSData dataWithBytes: ss length: strlen( ss)] forKey:@"compressedSopInstanceUID"];
		free( ss);
	}
	else [self setValue: 0L forKey:@"compressedSopInstanceUID"];
}

#pragma mark-

- (NSNumber*) inDatabaseFolder
{
	if( inDatabaseFolder) return inDatabaseFolder;
	
	NSNumber	*f = [self primitiveValueForKey:@"storedInDatabaseFolder"];
	
	if( f == 0L) f = [NSNumber numberWithBool: YES];
	
	[inDatabaseFolder release];
	inDatabaseFolder = [f retain];

	return inDatabaseFolder;
}

- (void) setInDatabaseFolder:(NSNumber*) f
{
	[inDatabaseFolder release];
	inDatabaseFolder = 0L;
	
	if( [f boolValue] == YES)	
		[self setPrimitiveValue: 0L forKey:@"storedInDatabaseFolder"];
	else
		[self setPrimitiveValue: f forKey:@"storedInDatabaseFolder"];
}

#pragma mark-

- (NSNumber*) height
{
	if( height) return height;
	
	NSNumber	*f = [self primitiveValueForKey:@"storedHeight"];
	
	if( f == 0L) f = [NSNumber numberWithInt: 512];
	
	[height release];
	height = [f retain];

	return height;
}

- (void) setHeight:(NSNumber*) f
{
	[height release];
	height = 0L;
	
	if( [f intValue] == 512)	
		[self setPrimitiveValue: 0L forKey:@"storedHeight"];
	else
		[self setPrimitiveValue: f forKey:@"storedHeight"];
}

#pragma mark-

- (NSNumber*) width
{
	if( width) return width;
	
	NSNumber	*f = [self primitiveValueForKey:@"storedWidth"];
	
	if( f == 0L) f = [NSNumber numberWithInt: 512];
	
	[width release];
	width = [f retain];

	return width;
}

- (void) setWidth:(NSNumber*) f
{
	[width release];
	width = 0L;
	
	if( [f intValue] == 512)	
		[self setPrimitiveValue: 0L forKey:@"storedWidth"];
	else
		[self setPrimitiveValue: f forKey:@"storedWidth"];
}

#pragma mark-

- (NSNumber*) numberOfFrames
{
	if( numberOfFrames) return numberOfFrames;
	
	NSNumber	*f = [self primitiveValueForKey:@"storedNumberOfFrames"];
	
	if( f == 0L) f = [NSNumber numberWithInt: 1];

	[numberOfFrames release];
	numberOfFrames = [f retain];

	return numberOfFrames;
}

- (void) setNumberOfFrames:(NSNumber*) f
{
	[numberOfFrames release];
	numberOfFrames = 0L;
	
	if( [f intValue] == 1)	
		[self setPrimitiveValue: 0L forKey:@"storedNumberOfFrames"];
	else
		[self setPrimitiveValue: f forKey:@"storedNumberOfFrames"];
}

#pragma mark-

- (NSNumber*) numberOfSeries
{
	if( numberOfSeries) return numberOfSeries;
	
	NSNumber	*f = [self primitiveValueForKey:@"storedNumberOfSeries"];
	
	if( f == 0L) f = [NSNumber numberWithInt: 1];

	[numberOfSeries release];
	numberOfSeries = [f retain];

	return numberOfSeries;
}

- (void) setNumberOfSeries:(NSNumber*) f
{
	[numberOfSeries release];
	numberOfSeries = 0L;
	
	if( [f intValue] == 1)	
		[self setPrimitiveValue: 0L forKey:@"storedNumberOfSeries"];
	else
		[self setPrimitiveValue: f forKey:@"storedNumberOfSeries"];
}

#pragma mark-

- (NSNumber*) mountedVolume
{
	if( mountedVolume) return mountedVolume;
	
	NSNumber	*f = [self primitiveValueForKey:@"storedMountedVolume"];
	
	if( f == 0L)  f = [NSNumber numberWithBool: NO];

	[mountedVolume release];
	mountedVolume = [f retain];

	return mountedVolume;
}

- (void) setMountedVolume:(NSNumber*) f
{
	[mountedVolume release];
	mountedVolume = 0L;
	
	if( [f boolValue] == NO)
		[self setPrimitiveValue: 0L forKey:@"storedMountedVolume"];
	else
		[self setPrimitiveValue: f forKey:@"storedMountedVolume"];
}

#pragma mark-

- (NSNumber*) isKeyImage
{
	if( isKeyImage) return isKeyImage;
	
	NSNumber	*f = [self primitiveValueForKey:@"storedIsKeyImage"];
	
	if( f == 0L)  f = [NSNumber numberWithBool: NO];

	[isKeyImage release];
	isKeyImage = [f retain];

	return isKeyImage;
}

- (void) setIsKeyImage:(NSNumber*) f
{
	[isKeyImage release];
	isKeyImage = 0L;
	
	if( [f boolValue] == NO)
		[self setPrimitiveValue: 0L forKey:@"storedIsKeyImage"];
	else
		[self setPrimitiveValue: f forKey:@"storedIsKeyImage"];
}

#pragma mark-

- (NSString*) extension
{
	if( extension) return extension;
	
	NSString	*f = [self primitiveValueForKey:@"storedExtension"];
	
	if( f == 0 || [f isEqualToString:@""]) f = [NSString stringWithString: @"dcm"];

	[extension release];
	extension = [f retain];

	return extension;
}

- (void) setExtension:(NSString*) f
{
	[extension release];
	extension = 0L;
	
	if( [f isEqualToString:@"dcm"])
		[self setPrimitiveValue: 0L forKey:@"storedExtension"];
	else
		[self setPrimitiveValue: f forKey:@"storedExtension"];
}

#pragma mark-

- (NSString*) modality
{
	if( modality) return modality;
	
	NSString	*f = [self primitiveValueForKey:@"storedModality"];
	
	if( f == 0 || [f isEqualToString:@""]) f = [NSString stringWithString: @"CT"];

	[modality release];
	modality = [f retain];

	return modality;
}

- (void) setModality:(NSString*) f
{
	[modality release];
	modality = 0L;
	
	if( [f isEqualToString:@"CT"])
		[self setPrimitiveValue: 0L forKey:@"storedModality"];
	else
		[self setPrimitiveValue: f forKey:@"storedModality"];
}

#pragma mark-

- (NSString*) fileType
{
	if( fileType) return fileType;
	
	NSString	*f = [self primitiveValueForKey:@"storedFileType"];
	
	if( f == 0 || [f isEqualToString:@""]) f =  [NSString stringWithString: @"DICOM"];
	
	[fileType release];
	fileType = [f retain];

	return fileType;
}

- (void) setFileType:(NSString*) f
{
	[fileType release];
	fileType = 0L;

	if( [f isEqualToString:@"DICOM"])
		[self setPrimitiveValue: 0L forKey:@"storedFileType"];
	else
		[self setPrimitiveValue: f forKey:@"storedFileType"];
}

#pragma mark-

- (void)setValue:(id)value forUndefinedKey:(NSString *)key
{
}

- (id)valueForUndefinedKey:(NSString *)key
{
	return 0L;
}

- (void) setDate:(NSDate*) date
{
	[dicomTime release];
	dicomTime = 0L;
	
	[self setPrimitiveValue: date forKey:@"date"];
}

- (NSNumber*) dicomTime
{
	if( dicomTime) return dicomTime;
	
	dicomTime = [[[DCMCalendarDate dicomTimeWithDate:[self valueForKey: @"date"]] timeAsNumber] retain];
	
	return dicomTime;
}

- (NSString*) type
{
	return  [NSString stringWithString: @"Image"];
}

- (void) dealloc
{
	[dicomTime release];
	[sopInstanceUID release];
	[inDatabaseFolder release];
	[height release];
	[width release];
	[numberOfFrames release];
	[numberOfSeries release];
	[mountedVolume release];
	[isKeyImage release];
	[extension release];
	[modality release];
	[fileType release];
	
	[completePathCache release];
	[super dealloc];
}

-(NSString*) uniqueFilename	// Return a 'unique' filename that identify this image...
{
	return [NSString stringWithFormat:@"%@ %@",[self valueForKey:@"sopInstanceUID"], [self valueForKey:@"instanceNumber"]];
}

- (void) clearCompletePathCache
{
	[completePathCache release];
	completePathCache = 0L;
}

+ (NSString*) completePathForLocalPath:(NSString*) path directory:(NSString*) directory
{
	if( [path characterAtIndex: 0] != '/')
	{
		NSString	*extension = [path pathExtension];
		long		val = [[path stringByDeletingPathExtension] intValue];
		NSString	*dbLocation = [directory stringByAppendingPathComponent: @"DATABASE"];
		
		val /= 10000;
		val++;
		val *= 10000;
		
		return [[dbLocation stringByAppendingPathComponent: [NSString stringWithFormat: @"%d", val]] stringByAppendingPathComponent: path];
	}
	else return path;
}

- (NSString*) path
{
	NSNumber	*pathNumber = [self primitiveValueForKey: @"pathNumber"];
	
	if( pathNumber)
	{
		return [NSString stringWithFormat:@"%d.dcm", [pathNumber intValue]];
	}
	else return [self primitiveValueForKey: @"pathString"];
}

- (void) setPath:(NSString*) p
{
	if( [p characterAtIndex: 0] != '/')
	{
		if( [[p pathExtension] isEqualToString:@"dcm"])
		{
			[self setPrimitiveValue: [NSNumber numberWithInt: [p intValue]] forKey:@"pathNumber"];
			[self setPrimitiveValue: 0L forKey:@"pathString"];
			
			return;
		}
	}
	
	[self setPrimitiveValue: 0L forKey:@"pathNumber"];
	[self setPrimitiveValue: p forKey:@"pathString"];
}

-(NSString*) completePathWithDownload:(BOOL) download
{
	if( completePathCache) return completePathCache;
	
	#ifdef OSIRIX_VIEWER
	if( [[self valueForKey:@"inDatabaseFolder"] boolValue] == YES)
	{
		NSString			*path = [self valueForKey:@"path"];
		BrowserController	*cB = [BrowserController currentBrowser];
		
		if( [cB isCurrentDatabaseBonjour])
		{
			if( download)
				completePathCache = [[[cB bonjourBrowser] getDICOMFile: [cB currentBonjourService] forObject: self noOfImages: 1] retain];
			else
				completePathCache = [[BonjourBrowser uniqueLocalPath: self] retain];
			
			return completePathCache;
		}
		else
		{
			if( [path characterAtIndex: 0] != '/')
			{
				completePathCache = [[DicomImage completePathForLocalPath: path directory: [cB fixedDocumentsDirectory]] retain];
				return completePathCache;
			}
		}
	}
	#endif
	
	return [self valueForKey:@"path"];
}

-(NSString*) completePathResolved
{
	return [self completePathWithDownload: YES];
}

-(NSString*) completePath
{
	return [self completePathWithDownload: NO];
}

- (BOOL)validateForDelete:(NSError **)error
{
	BOOL delete = [super validateForDelete:(NSError **)error];
	if (delete)
	{
		#ifdef OSIRIX_VIEWER
		if( [[self valueForKey:@"inDatabaseFolder"] boolValue] == YES)
		{
			[[BrowserController currentBrowser] addFileToDeleteQueue: [self valueForKey:@"completePath"]];
			
			NSString *pathExtension = [[self valueForKey:@"path"] pathExtension];
			
			if( [pathExtension isEqualToString:@"hdr"])		// ANALYZE -> DELETE IMG
			{
				[[BrowserController currentBrowser] addFileToDeleteQueue: [[[self valueForKey:@"completePath"] stringByDeletingPathExtension] stringByAppendingPathExtension:@"img"]];
			}
			else if([pathExtension isEqualToString:@"zip"])		// ZIP -> DELETE XML
			{
				[[BrowserController currentBrowser] addFileToDeleteQueue: [[[self valueForKey:@"completePath"] stringByDeletingPathExtension] stringByAppendingPathExtension:@"xml"]];
			}
			
			[self setValue:[NSNumber numberWithBool:NO] forKey:@"inDatabaseFolder"];
		}
		
		if( [[NSFileManager defaultManager] fileExistsAtPath: [VRController getUniqueFilenameScissorStateFor: self]])
		{
			[[NSFileManager defaultManager] removeFileAtPath: [VRController getUniqueFilenameScissorStateFor: self] handler: 0L];
		}
		#endif
	}
	return delete;
}

- (NSSet *)paths{
	return [NSSet setWithObject:[self completePath]];
}

// DICOM Presentation State
- (DCMSequenceAttribute *)graphicAnnotationSequence{
	//main sequnce that includes the graphics overlays : ROIs and annotation
	DCMSequenceAttribute *graphicAnnotationSequence = [DCMSequenceAttribute sequenceAttributeWithName:@"GraphicAnnotationSequence"];
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//need the original file to get SOPClassUID and possibly SOPInstanceUID
	DCMObject *imageObject = [DCMObject objectWithContentsOfFile:[self primitiveValueForKey:@"completePath"] decodingPixelData:NO];
	
	//ref image sequence only has one item.
	DCMSequenceAttribute *refImageSequence = [DCMSequenceAttribute sequenceAttributeWithName:@"ReferencedImageSequence"];
	DCMObject *refImageObject = [DCMObject dcmObject];
	[refImageObject setAttributeValues:[self primitiveValueForKey:@"sopInstanceUID"] forName:@"ReferencedSOPInstanceUID"];
	[refImageObject setAttributeValues:[[imageObject attributeValueWithName:@"SOPClassUID"] values] forName:@"ReferencedSOPClassUID"];
	// may need to add references frame number if we add a frame object  Nothing here yet.
	
	[refImageSequence addItem:refImageObject];
	
	// Some basic graphics info
	
	DCMAttribute *graphicAnnotationUnitsAttr = [DCMAttribute attributeWithAttributeTag:[DCMAttributeTag tagWithName:@"GraphicAnnotationUnits"]];
	[graphicAnnotationUnitsAttr setValues:[NSMutableArray arrayWithObject:@"PIXEL"]];
	
	
	
	//loop through the ROIs and add
	NSSet *rois = [self primitiveValueForKey:@"rois"];
	NSEnumerator *enumerator = [rois objectEnumerator];
	id roi;
	while (roi = [enumerator nextObject]){
		//will be either a Graphic Object sequence or a Text Object Sequence
		int roiType = [[roi valueForKey:@"roiType"] intValue];
		NSString *typeString = nil;
		if (roiType == tText) {// is text 
		}
		else // is a graphic
		{
			switch (roiType) {
				case tOval:
					typeString = @"ELLIPSE";
					break;
				case tOPolygon:
				case tCPolygon:
					typeString = @"POLYLINE";
					break;
			}
		}
		
	}	
	[pool release];
	 return graphicAnnotationSequence;
}

- (NSImage *)image
{
	#ifdef OSIRIX_VIEWER
	DCMPix *pix = [[DCMPix alloc] myinit:[self valueForKey:@"completePath"] :0 :0 :0L :0 :[[self valueForKeyPath:@"series.id"] intValue] isBonjour:NO imageObj:self];
	//[pix computeWImage:NO :[[self valueForKeyPath:@"series.windowLevel"] floatValue] :[[self valueForKeyPath:@"series.windowWidth"] floatValue]];
	[pix computeWImage:NO :0 :0];
	NSData	*data = [[pix getImage] TIFFRepresentation];
	NSImage *thumbnail = [[[NSImage alloc] initWithData: data] autorelease];

	[pix release];
	return thumbnail;
	#endif

}
- (NSImage *)thumbnail
{
	#ifdef OSIRIX_VIEWER
	DCMPix *pix = [[DCMPix alloc] myinit:[self valueForKey:@"completePath"] :0 :0 :0L :0 :[[self valueForKeyPath:@"series.id"] intValue] isBonjour:NO imageObj:self];
	//[pix computeWImage:YES :[[self valueForKeyPath:@"series.windowLevel"] floatValue] :[[self valueForKeyPath:@"series.windowWidth"] floatValue]];
	[pix computeWImage:YES :0 :0];
	NSData	*data = [[pix getImage] TIFFRepresentation];
	NSImage *thumbnail = [[[NSImage alloc] initWithData: data] autorelease];
	[pix release];
	return thumbnail;
	#endif
}

- (NSDictionary *)dictionary{
	NSMutableDictionary *dict = [NSMutableDictionary dictionary];
	return dict;
}
	
- (NSString*) description
{
	NSString	*result = [super description];
	return [result stringByAppendingFormat:@"\rdicomTime: %@\rsopInstanceUID: %@", [self dicomTime], [self sopInstanceUID]];
}

@end
