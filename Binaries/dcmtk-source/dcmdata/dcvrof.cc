/*
 *
 *  Copyright (C) 2002, OFFIS
 *
 *  This software and supporting documentation were developed by
 *
 *    Kuratorium OFFIS e.V.
 *    Healthcare Information and Communication Systems
 *    Escherweg 2
 *    D-26121 Oldenburg, Germany
 *
 *  THIS SOFTWARE IS MADE AVAILABLE,  AS IS,  AND OFFIS MAKES NO  WARRANTY
 *  REGARDING  THE  SOFTWARE,  ITS  PERFORMANCE,  ITS  MERCHANTABILITY  OR
 *  FITNESS FOR ANY PARTICULAR USE, FREEDOM FROM ANY COMPUTER DISEASES  OR
 *  ITS CONFORMITY TO ANY SPECIFICATION. THE ENTIRE RISK AS TO QUALITY AND
 *  PERFORMANCE OF THE SOFTWARE IS WITH THE USER.
 *
 *  Module:  dcmdata
 *
 *  Author:  Joerg Riesmeier
 *
 *  Purpose: Implementation of class DcmOtherFloat
 *
 *  Last Update:      $Author: lpysher $
 *  Update Date:      $Date: 2006/03/01 20:15:22 $
 *  Source File:      $Source: /cvsroot/osirix/osirix/Binaries/dcmtk-source/dcmdata/dcvrof.cc,v $
 *  CVS/RCS Revision: $Revision: 1.1 $
 *  Status:           $State: Exp $
 *
 *  CVS/RCS Log at end of file
 *
 */


#include "osconfig.h"    /* make sure OS specific configuration is included first */

#include "dcvrof.h"
#include "dcvrfl.h"


// ********************************


DcmOtherFloat::DcmOtherFloat(const DcmTag &tag,
                             const Uint32 len)
  : DcmFloatingPointSingle(tag, len)
{
}


DcmOtherFloat::DcmOtherFloat(const DcmOtherFloat &old)
  : DcmFloatingPointSingle(old)
{
}


DcmOtherFloat::~DcmOtherFloat()
{
}


DcmOtherFloat &DcmOtherFloat::operator=(const DcmOtherFloat &obj)
{
    DcmFloatingPointSingle::operator=(obj);
    return *this;
}


// ********************************


DcmEVR DcmOtherFloat::ident() const
{
    return EVR_OF;
}


unsigned int DcmOtherFloat::getVM()
{
    /* value multiplicity for OF is defined as 1 */
    return 1;
}


/*
 * CVS/RCS Log:
 * $Log: dcvrof.cc,v $
 * Revision 1.1  2006/03/01 20:15:22  lpysher
 * Added dcmtkt ocvs not in xcode  and fixed bug with multiple monitors
 *
 * Revision 1.2  2005/12/08 15:41:58  meichel
 * Changed include path schema for all DCMTK header files
 *
 * Revision 1.1  2002/12/06 12:07:02  joergr
 * Added support for new value representation Other Float String (OF).
 *
 *
 */
