/*
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 *
 *  Copyrights:
 *
 *  Copyright - 1999 Sun Microsystems, Inc. All rights reserved.
 *  901 San Antonio Road, Palo Alto, California 94043, U.S.A.
 *
 *  This product and related documentation are protected by copyright and
 *  distributed under licenses restricting its use, copying, distribution, and
 *  decompilation. No part of this product or related documentation may be
 *  reproduced in any form by any means without prior written authorization of
 *  Sun and its licensors, if any.
 *
 *  RESTRICTED RIGHTS LEGEND: Use, duplication, or disclosure by the United
 *  States Government is subject to the restrictions set forth in DFARS
 *  252.227-7013 (c)(1)(ii) and FAR 52.227-19.
 *
 *  The product described in this manual may be protected by one or more U.S.
 *  patents, foreign patents, or pending applications.
 *
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 *
 *  Author:
 *
 *  Mahindra British Telecom
 *  155 , Bombay - Pune Road 
 *  Pimpri ,
 *  Pune - 411 018.
 *
 *  Module Name   : JAIN INAP API
 *  File Name     : HoldCallInNetwork.java
 *  Approver      : Jain Inap Edit Group
 *  Version       : 1.0
 *
 *~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 */


package javax.jain.ss7.inap.operation;

import java.io.*;
import java.util.*;
import javax.jain.ss7.inap.datatype.*;
import javax.jain.ss7.inap.constants.*;
import javax.jain.*;


/**
This class represents the HoldCallInNetwork Operation.
*/

public class HoldCallInNetwork  extends Operation   implements java.io.Serializable
{
	private String holdCause;
	private boolean isHoldCause = false ;

/**
Constructor For HoldCallInNetwork
*/

	public HoldCallInNetwork() 
	{
		operationCode = OperationCode.HOLD_CALL_IN_NETWORK;
	
	}


//-----------------------

/**
Gets Operation Code
*/
    public OperationCode getOperationCode() 
    {
        return operationCode;
    }

//-----------------------

/**
Gets Hold Cause
*/
    public java.lang.String getHoldCause() throws ParameterNotSetException
    {
        if(isHoldCausePresent()) 
             return holdCause;
        else
             throw new ParameterNotSetException();
    }
/**
Sets Hold Cause
*/
    public void setHoldCause(java.lang.String holdCause)
    {
        this.holdCause = holdCause;
        isHoldCause = true;
    }
/**
Indicates if the Hold Cause optional parameter is present .
Returns: TRUE if present, FALSE otherwise.
*/
    public boolean isHoldCausePresent()
    {
        return isHoldCause;
    }

//-----------------------
}    