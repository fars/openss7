/*
 @(#) src/java/javax/csapi/cc/jcc/InvalidStateException.java <p>
 
 Copyright &copy; 2008-2015  Monavacon Limited <a href="http://www.monavacon.com/">&lt;http://www.monavacon.com/&gt;</a>. <br>
 Copyright &copy; 2001-2008  OpenSS7 Corporation <a href="http://www.openss7.com/">&lt;http://www.openss7.com/&gt;</a>. <br>
 Copyright &copy; 1997-2001  Brian F. G. Bidulock <a href="mailto:bidulock@openss7.org">&lt;bidulock@openss7.org&gt;</a>. <p>
 
 All Rights Reserved. <p>
 
 This program is free software: you can redistribute it and/or modify it under
 the terms of the GNU Affero General Public License as published by the Free
 Software Foundation, version 3 of the license. <p>
 
 This program is distributed in the hope that it will be useful, but <b>WITHOUT
 ANY WARRANTY</b>; without even the implied warranty of <b>MERCHANTABILITY</b>
 or <b>FITNESS FOR A PARTICULAR PURPOSE</b>.  See the GNU Affero General Public
 License for more details. <p>
 
 You should have received a copy of the GNU Affero General Public License along
 with this program.  If not, see
 <a href="http://www.gnu.org/licenses/">&lt;http://www.gnu.org/licenses/&gt</a>,
 or write to the Free Software Foundation, Inc., 675 Mass Ave, Cambridge, MA
 02139, USA. <p>
 
 <em>U.S. GOVERNMENT RESTRICTED RIGHTS</em>.  If you are licensing this
 Software on behalf of the U.S. Government ("Government"), the following
 provisions apply to you.  If the Software is supplied by the Department of
 Defense ("DoD"), it is classified as "Commercial Computer Software" under
 paragraph 252.227-7014 of the DoD Supplement to the Federal Acquisition
 Regulations ("DFARS") (or any successor regulations) and the Government is
 acquiring only the license rights granted herein (the license rights
 customarily provided to non-Government users).  If the Software is supplied to
 any unit or agency of the Government other than DoD, it is classified as
 "Restricted Computer Software" and the Government's rights in the Software are
 defined in paragraph 52.227-19 of the Federal Acquisition Regulations ("FAR")
 (or any successor regulations) or, in the cases of NASA, in paragraph
 18.52.227-86 of the NASA Supplement to the FAR (or any successor regulations). <p>
 
 Commercial licensing and support of this software is available from OpenSS7
 Corporation at a fee.  See
 <a href="http://www.openss7.com/">http://www.openss7.com/</a>
 */

package javax.csapi.cc.jcc;

/** An InvalidStateException indicates that that current state of an
  * object involved in the method invocation does not meet the
  * acceptable pre-conditions for the method.
  * Each method which changes the call model typically has a set of
  * states in which the object must be as a pre-condition for the
  * method. Each method documents the pre-condition states for objects.
  * Typically, this method might succeed later when the object in
  * question reaches the proper state.  <p>
  * This exception provides the application with the object in question
  * and the state of the object.
  * @version 1.2.2
  * @author Monavacon Limited
  * @since 1.0b */
public class InvalidStateException extends Exception {
    /** The invalid object in question is the Provider */
    public static final int PROVIDER_OBJECT = 0;
    /** The invalid object in question is the Call */
    public static final int CALL_OBJECT = 1;
    /** The invalid object in question is the Connection */
    public static final int CONNECTION_OBJECT = 2;
    /** The invalid object in question is the Address */
    public static final int ADDRESS_OBJECT = 4;
    /** Constructor with no string.
      * @param object
      * Instance associated with the invalid sate.
      * @param type
      * Type of failure.
      * @param state
      * Current state at time of fault. */
    public InvalidStateException(java.lang.Object object, int type, int state) {
        super();
        setObject(object);
        setType(type);
        setState(state);
    }
    public void setObject(java.lang.Object object) {
        m_object = object;
    }
    public void setType(int type) {
        m_type = type;
    }
    public void setState(int state) {
        m_state = state;
    }
    /** Constructor which takes a string description.
      * @param object
      * Instance associated with the invalid sate.
      * @param type
      * Type of failure.
      * @param state
      * Current state at time of fault.
      * @param s
      * Desciption of the fault.  */
    public InvalidStateException(java.lang.Object object, int type, int state, java.lang.String s) {
        super(s);
        setObject(object);
        setType(type);
        setState(state);
    }
    /** Returns the type of object in question.
      * @return The type of object in question.  */
    public int getObjectType() {
        return m_type;
    }
    /** Returns the object which has the incorrect state.
      * @return
      * The object which is in the wrong state.  */
    public java.lang.Object getObject() {
        return m_object;
    }
    /** Returns the state of the object.
      * @return
      * The state of the object.  */
    public int getState() {
        return m_state;
    }
    /** The type of the party.  @serial */
    private int m_type;
    /** The current state.  @serial */
    private int m_state;
    /** The current object.  @serial */
    private java.lang.Object m_object;
}

// vim: sw=4 et tw=72 com=srO\:/**,mb\:*,ex\:*/,srO\:/*,mb\:*,ex\:*/,b\:TRANS,\://,b\:#,\:%,\:XCOMM,n\:>,fb\:-
