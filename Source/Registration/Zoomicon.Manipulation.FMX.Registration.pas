unit Zoomicon.Manipulation.FMX.Registration;

interface

  procedure Register;

implementation
  {$region 'Used units'}
  uses
    //DesignIntf, //for ForceDemandLoadState
    System.Classes, //for RegisterComponents
    Zoomicon.Manipulation.FMX.CustomManipulator, //for TCustomManipulator
    Zoomicon.Manipulation.FMX.Manipulator, //for TManipulator
    Zoomicon.Manipulation.FMX.Selector; //for TLocationSelector, TAreaSelector
  {$endregion}

  procedure Register; //only called by IDE on installed package
  begin
    RegisterComponents('Zoomicon', [{TCustomManipulator,} TManipulator, TLocationSelector, TAreaSelector]); //Not registering TCustomManipulator on the IDE palette, only descendant classes

    //ForceDemandLoadState(dlDisable); //disable lazy-loading of package
  end;


end.
