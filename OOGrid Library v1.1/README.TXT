

                           OOGrid Library(TM) v1.1
                   for Borland/Turbo Pascal (Real Mode/TV)
                            Release date 06/01/95
                                       
                                       
                           Copyright (C) 1994, 1995
                              by Arturo J. Monge
                                       
                                       
                       Portions Copyright (C) 1989,1990
                        by Borland International, Inc.
                                       
                                       
                                  README.TXT


A. WHAT IS 'OOGrid Library (TM)'?

     OOGrid Library(TM) is a library of objects for Turbo Vision that
provides a simple spreadsheet for use in your applications.  The spreadsheet
in OOGrid Library(TM) can be used, for example, to manage lists, to browse
and edit the data in a database, to create data entry screens or simply as an
ordinary spreadsheet.  The library consists of one main object --
TSpreadSheet -- and several auxiliary objects used by TSpreadSheet.  Some of
these auxiliary objects (TLimScrollBar, TMessageLine, and TWindowList -- the
latter implemented in the demo program) can be used by other objects or
applications not related to OOGrid Library(TM).

     This library works with Turbo Pascal 6.0 and Borland/Turbo Pascal 7.0,
and can be used to create real mode applications only; it does not work
properly in protected mode applications.


B. WHAT DOES 'OOGrid Library(TM)' DO?

     The spreadsheet object provided with OOGrid Library(TM) can handle text,
values, formulas and repeat characters.  It supports several numerical
functions (abs, trunc, round, exp, sin, cos, atan, sqr, sqrt, and ln) and
operations (+, -, /, *, :, and ^) that can be used in formula or value cells. 
It lets you mark, copy, move and erase blocks of cells, insert and delete
columns and rows, change the width of a column or block of columns, and
assign a custom header to any column in the spreadsheet. You can justify
(left, center or right) the contents of a cell, and format numbers by adding
commas, a currency character or by changing the number of decimals displayed. 
There is also a sort function that lets you sort the rows of a block of cells
using three different sort keys, in either ascending or descending order.

     The spreadsheet supports three modes of operation that you can toggle on
and off independently: autocalc mode, in which all the formula cells are
recalculated every time you add or modify a cell; display formulas mode, in
which all formulas and not their results are displayed; and display headers
mode, in which all custom assigned headers are displayed. There is also a
spreadsheet protection feature, that lets you protect the data in the
spreadsheet; when the spreadsheet is protected, only marked (unlocked) cells
can be changed.  This feature is useful for creating data entry screens.
 
     The spreadsheet also offers several printing options.  You can print a
file in normal or condensed mode and choose whether or not to print the
column headers and/or the row numbers.  You can print row outlines and print
the column headers and row numbers in bold characters, and also define the
page layout (margins and number of columns and rows in a page).


C. SOURCE CODE

     More than 100 pages of source code are included with OOGrid Library(TM). 
The source code of GLCELL.PAS, GLLSTR.PAS, GLPARSER.PAS, TCHASH.PAS and
TCUTIL.PAS are partially or completely copyrighted by Borland International,
Inc. 


D. LICENSE AGREEMENT

     You must read and accept the license agreement before using OOGrid
Library(TM) for Borland/Turbo Pascal (Real Mode/TV).  See the file
LICENSE.TXT. 


E. DESCRIPTION OF FILES

     Before using OOGrid Library(TM) the first time, make sure you have all
the following files;  if not, please contact the author immediately.

 Demo files:

     DEMOEQU.PAS    Equates unit for the demo program
     DEMOMAKE.PAS   Program that creates the resource file used by the demo
                    program
     DEMO_GL.EXE    Demo program
     DEMO_GL.PAS    Source code of the demo program

 Example files:

     EX_ENTRY.OGL   Two examples of data entry screens
     EX_ERROR.OGL   Different errors reported by TSpreadSheet
     EX_FUNCT.OGL   Different functions and operations supported by
                    TSpreadSheet
     EX_LICEN.OGL   License agreement.  MUST READ!
     EX_LIST1.OGL   Some information about column headers and the sort
                    function
     EX_LIST2.OGL   An example list
     EX_OOGL2.OGL   Information about next releases
     EX_TYPES.OGL   Examples of the different types of cells supported by
                    TSpreadSheet

 Source code files:

     GLEQUATE.PAS   Equates unit used by TSpreadSheet
     GLSORT.PAS     Implementation of an object that can sort a cell hash
                    table using three different keys
     GLSUPPRT.PAS   Several support constants, variables, records and objects
                    used by TSpreadSheet
     GLTSHEET.PAS   This is the main unit, which implements the TSpreadSheet
                    object
     GLTVR_US.PAS   Implements two functions needed to create the resources
                    used by TSpreadSheet (English)
     GLTVR_SP.PAS   Implements two functions needed to create the resources
                    used by TSpreadSheet (Spanish)
     GLVIEWS.PAS    Implementation of several support views used by
                    TSpreadSheet
     GLWINDOW.PAS   Implementation of a TWindow's descendant that can own a
                    TSpreadSheet object
     GLCELL.PAS     Implementation of the different cell and hash table
                    objects used by TSpreadSheet.
     GLLSTR.PAS     Implementation of a long string object. 
     GLPARSER.PAS   Implementation of the parser used by TSpreadSheet.  
     GLBIULD.PAS    Used to build all the units in OOGrid Library(TM)
     TCHASH.PAS     Implementation of the HashTable object
     TCUTIL.PAS     Implementation of several support functions used by
                    TSpreadSheet
     TCCOMPAR.OBJ   Object code used by TCUTIL.PAS

 Text files:

     README.TXT     This file.
     LICENSE.TXT    License agreement.  MUST READ!
     NEXTRLSE.TXT   Information about future releases of OOGrid Library(TM)
     MANUAL.TXT     Documentation of most of the units in OOGrid Library(TM)
     REVISION.TXT   Changes made to OOGrid Library(TM) and its documentation
     VENDORS.TXT    Information for vendors

 Utilities

     PRINTDOC.EXE   Use this program to print the documentation
     PRINTDOC.PAS   Source code of the PRINTDOC.EXE program


F. REQUIREMENTS

     Turbo Pascal 6.0 or Borland/Turbo Pascal 7.0
     Turbo Vision 1.0 or Turbo Vision 2.0


G. HOW TO USE 'OOGrid Library (TM)'

     There are several things that you must do before creating the first
instance of a TSpreadSheet object in an application:

     1- Create a resource file, using the CreateOOGLDialogs and
     CreateOOGLStrings functions in the GLTVR_US unit.

     2- Add new palette entries to the standard application palettes.

     3- Assign values to two pointer variables:

     a) GLResFile, which is a pointer to the resource file containing the
     dialogs created using the CreateOOGLDialogs function (seeGLTVR_US.PAS). 
     Remember to close and dispose the corresponding resource file before
     terminating your application.

     b) GLStringList, which is a pointer to the string list created using the
     CreateOOGLStrings function (see GLTVR_US.PAS).  Remember to dispose the
     corresponding TStringList object before terminating your application.


     The source code in DEMOMAKE.PAS and DEMO_GL.PAS shows you how to create
the resource file needed by TSpreadSheet, extend the standard application
palettes, initialize the GLResFile and GLStringList variables, and how to use
a TSpreadSheetWindow and TSpreadSheet object in an application.


H. ABOUT THE DOCUMENTATION

     The file MANUAL.TXT contains the documentation of OOGrid Library(TM).
There is a short description of almost every unit in this library, and a
description, in alphabetical order, of almost every variable, constant and
type declared in those units.  Each description has an identifier
declaration, the unit in which the identifier is declared, its function, its
parameters' description (if any) and important remarks about the identifier
(if any).

     The units GLPARSER.PAS, GLLSTR.PAS, TCHASH.PAS and TCUTIL.PAS are not
documented.


I. HOW TO CONTACT THE AUTHOR

You can contact the author at any of the addresses listed below:

 E-MAIL:
      INTERNET:          mongev@ns.fing.ucr.ac.cr
      CLEVELAND FREENET: fh441@freenet.cleveland.edu

 MAIL:
      Arturo J. Monge
      SJO 1684; POB 025216
      Miami, FL 33102-5216

Sending correspondence via electronic mail is strongly preferred.

Please feel free to contact the author at any time to share your comments
about this software and/or licensing policies, to ask questions about the use
of this library and (please!) to report any bugs you may find.

Thanks a lot for your support!
