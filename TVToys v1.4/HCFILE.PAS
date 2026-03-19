(***************************************************************************
  hcFile include
  The name of your help context file
  PJB November 20, 1993, Internet mail to d91-pbr@nada.kth.se

  Enter here the name of the help context file you are using, the
  default is HelpCtx. The help context file name is the same as the
  third parameter to TVHC. If you change the name, make sure the new file
  exists before you attempt to recompile TVTOYS.

  Help contexts will come from the below file which is included in TVTOYS,
  but a local HelpCtx file will override TVToys'.
  If any TVToys topics are missing, TOYPREFS include dummy values to
  avoid compile errors.

  You might have to rebuild to get the right contexts into TVToys.

***************************************************************************)

  HelpCtx,              (* My personal help context file *)
