//Description: CustomManipulator (FMX)
//Author: George Birbilis (http://zoomicon.com)

unit Zoomicon.Manipulation.FMX.CustomManipulator;

interface
  {$region 'Used units'}
  uses
    System.Classes, //for TShiftState
    System.Math, //for Min, EnsureInRange (inlined)
    System.Types,
    System.UITypes,
    //
    FMX.Types,
    FMX.Controls,
    FMX.Forms,
    FMX.ExtCtrls, //for TDropTarget
    FMX.Gestures, //TODO: is this needed here?
    FMX.Objects, //for TSelection
    //
    Zoomicon.Manipulation.FMX.Selector; //for TLocationSelector, TAreaSelector
  {$endregion}

  const
    SELECTION_GRIP_SIZE = 8;
    DEFAULT_AUTOSIZE = false;
    DEFAULT_EDITMODE = false;
    DEFAULT_PROPORTIONAL = false;

  type

    {$REGION 'TCustomManipulator' -----------------------------------------------------}

    TCustomManipulator = class(TFrame)
    protected
      FEditMode: Boolean;
      FDragging: Boolean;
      FMouseShift: TShiftState; //TODO: if Delphi fixes the Shift parameter to not be empty at MouseClick (seems to be empty at MouseUp too btw) in the future, remove this
      FLastAreaSelectorBounds: TRectF;
      FAreaSelectorChanging: Boolean;
      FAreaSelector_SelectedControls: TControlList;

      {Gestures}
      FLastPosition: TPointF;
      FLastDistance: Integer;

      FAreaSelector: TAreaSelector;
      FDropTarget: TDropTarget;
      FAutoSize: Boolean;
      FDragStartLocation: TPointF;

      procedure Loaded; override;
      procedure ApplyEditModeToChild(Control: TControl);
      procedure DoAddObject(const AObject: TFmxObject); override;
      procedure DoAutoSize;

      {Z-order}
      function GetBackIndex: Integer; override;
      procedure SetDropTargetZorder; virtual;

      {AreaSelector}
      procedure SetAreaSelector(const Value: TAreaSelector);

      {AutoSize}
      procedure SetAutoSize(const Value: Boolean); virtual;

      {DropTargetVisible}
      function IsDropTargetVisible: Boolean; virtual;
      procedure SetDropTargetVisible(const Value: Boolean); virtual;

      {EditMode}
      function IsEditMode: Boolean; virtual;
      procedure SetEditMode(const Value: Boolean); virtual;

      {Proportional}
      function IsProportional: Boolean; virtual;
      procedure SetProportional(value: Boolean); virtual;

      {$region 'Events'}
      {AreaSelector}
      procedure HandleAreaSelectorMoving(Sender: TObject; const DX, DY: Single; out Canceled: Boolean); virtual;
      procedure HandleAreaSelectorMoved(Sender: TObject; const DX, DY: Single); virtual;
      procedure HandleAreaSelectorTrack(Sender: TObject); virtual; //called while user resizes the area selector
      procedure HandleAreaSelectorChange(Sender: TObject); virtual; //called when user finishes resizing the area selector
      procedure HandleAreaSelectorMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single); virtual;

      {Gestures}
      procedure DoGesture(const EventInfo: TGestureEventInfo; var Handled: Boolean); override;
      procedure HandlePan(EventInfo: TGestureEventInfo);
      procedure HandleRotate(EventInfo: TGestureEventInfo);
      procedure HandleZoom(EventInfo: TGestureEventInfo);
      procedure HandlePressAndTap(EventInfo: TGestureEventInfo);

      {Mouse}
      procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
      procedure MouseMove(Shift: TShiftState; X, Y: Single); override;
      procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
      procedure MouseClick(Button: TMouseButton; Shift: TShiftState; X, Y: Single); override;
      procedure MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean); override;

      {DragDrop}
      procedure DragEnter(const Data: TDragObject; const Point: TPointF); override;
      procedure DragLeave; override;
      procedure DropTargetDragOver(Sender: TObject; const Data: TDragObject; const Point: TPointF; var Operation: TDragOperation); virtual;
      procedure DropTargetDropped(Sender: TObject; const Data: TDragObject; const Point: TPointF); overload; virtual;
      procedure DropTargetDropped(const Filepaths: array of string); overload; virtual;
      {$endregion}

    public
      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;

      {$region 'Manipulation'}
      {Z-order}
      procedure BringToFrontElseSendToBack(const Control: TControl); overload; inline;
      procedure BringToFrontElseSendToBack(const Controls: TControlList); overload;
      procedure BringToFrontElseSendToBackSelected;

      {Move}
      procedure MoveControl(const Control: TControl; const DX, DY: Single; const SkipAutoSize: Boolean = false); overload; inline;
      procedure MoveControls(const Controls: TControlList; const DX, DY: Single); overload;
      procedure MoveControls(const DX, DY: Single); overload;
      procedure MoveSelected(const DX, DY: Single);

      {Resize}
      procedure ResizeControl(const Control: TControl; const SDW, SDH: Single; const SkipAutoSize: Boolean = false); overload; inline; //SDH, SDW are scaled deltas
      procedure ResizeControls(const Controls: TControlList; const SDW, SDH: Single); overload;
      procedure ResizeControls(const SDW, SDH: Single); overload;
      procedure ResizeSelected(const SDW, SDH: Single); overload;
      procedure ResizeControl(const Control: TControl; const TheBounds: TRectF; const SkipAutoSize: Boolean = false); overload; inline;
      procedure ResizeControls(const Controls: TControlList; const TheBounds: TRectF); overload;
      procedure ResizeControls(const TheBounds: TRectF); overload;
      procedure ResizeSelected(const TheBounds: TRectF); overload;

      {Rotate}
      procedure SetControlAngle(const Control: TControl; const Angle: Single); overload; inline;
      procedure RotateControl(const Control: TControl; const DAngle: Single; const SkipAutoSize: Boolean = false); overload; inline;
      procedure RotateControls(const Controls: TControlList; const DAngle: Single); overload;
      procedure RotateControls(const DAngle: Single); overload;
      procedure RotateSelected(const DAngle: Single);
      {$endregion}

      property AreaSelector: TAreaSelector read FAreaSelector write SetAreaSelector stored false;
      property DropTarget: TDropTarget read FDropTarget stored false;
      property AutoSize: Boolean read FAutoSize write SetAutoSize default DEFAULT_AUTOSIZE;
      property DropTargetVisible: Boolean read IsDropTargetVisible write SetDropTargetVisible stored false default DEFAULT_EDITMODE;
      property EditMode: Boolean read IsEditMode write SetEditMode default DEFAULT_EDITMODE;
      property Proportional: Boolean read IsProportional write SetProportional default DEFAULT_PROPORTIONAL;
    end;

    {$ENDREGION}

implementation
  {$region 'Used units'}
  uses
    System.SysUtils, //for Supports
    System.Rtti, //for TValue
    //
    Zoomicon.Helpers.FMX.Controls.ControlHelper, //for TControl.ObjectAtXX, TControl.ConvertLocalRectXX, TControl.SubComponent
    Zoomicon.Generics.Functors, //for TF
    Zoomicon.Generics.Collections; //for TListEx
  {$endregion}

  {$R *.fmx}

  {$region 'Utils'}

  procedure Swap(var a, b: Single); inline; //there's no Swap(Single, Single) or SwapF
  begin
    var temp := a;
    a := b;
    b := temp;
  end;

  procedure Order(var a, b: Single); inline;
  begin
    if (a > b) then
      Swap(a, b);
  end;

  {
  procedure Order(var a, b, c: Single); inline;
  begin
    if (a > b) then
      Swap(a, b);
    if (b > c) then
      Swap(b, c);
  end;
  }

  {$endregion}

  {$REGION 'TCustomManipulator' -----------------------------------------------}

  constructor TCustomManipulator.Create(AOwner: TComponent);
  begin
    inherited; //this will also load designer resource, which will call Loaded and create subcomponents

    AutoSize := DEFAULT_AUTOSIZE; //must do after CreateAreaSelector
    EditMode := DEFAULT_EDITMODE;
    Proportional := DEFAULT_PROPORTIONAL;
  end;

  destructor TCustomManipulator.Destroy;
  begin
    ReleaseCapture; //make sure we always release Mouse Capture
    FreeAndNil(FAreaSelector_SelectedControls);

    inherited; //do last
  end;

  procedure TCustomManipulator.Loaded;

    procedure CreateAreaSelector;
    begin
       SetAreaSelector(TAreaSelector.Create(Self)); //must set ourselves as the owner, note we don't assign manually to "FAreaSelector"
       FAreaSelector.Parent := Self; //Note: must not set parent in "SetAreaSelector" for externally provided AreaSelector, setting it for internally created ones only at the constructor
    end;

    procedure CreateLocationSelector;
    begin
      var LocationSelector := TLocationSelector.Create(FAreaSelector); //don't use Self so that the middle SelectionPoint doesn't show up in the frame designer
      with LocationSelector do
        begin
        Stored := False; //don't store state
        SetSubComponent(true); //don't show in Designer for descendents

        ParentBounds := false; //CAN move outside of parent area

        GripSize := SELECTION_GRIP_SIZE;
        Align := TAlignLayout.Center;

        OnParentMoving := HandleAreaSelectorMoving;
        OnParentMoved := HandleAreaSelectorMoved;

        Parent := FAreaSelector;
        end;
    end;

    procedure CreateDropTarget;
    begin
      FDropTarget := TDropTarget.Create(Self);
      with FDropTarget do
      begin
        Stored := False; //don't store state
        SetSubComponent(true); //don't show in Designer for descendents
        HitTest := False; //TODO: check if needed for drag-drop
        Visible := EditMode;
        Opacity := 0.4;
        //not doing SendToBack, assuming it's created first, since we reserve one place for it at the bottom with GetBackIndex
        Align := TAlignLayout.Client;
        SetDropTargetZorder;

        (* //comment out, doesn't seem to work (need to make "Path" invisible using the Style Designer if don't want to see the "drop" arrow)
        var P := TStyledControl.Create(nil);
        Parent := P;
        P.StylesData['droptargetstyle.Path.Visible']:= TValue.From(false);
        Parent := nil;
        FreeAndNil(P);
        *)

        Enabled := true;
        OnDragOver := DropTargetDragOver;
        OnDropped := DropTargetDropped;
      end;
      DropTarget.Parent := Self;
    end;

  begin
    inherited;
    CreateDropTarget;
    CreateAreaSelector;
    //CreateLocationSelector; //must do after CreateAreaSelector //NOT USED ANYMORE
  end;

  {$region 'Manipulation'}

  {$region 'Z-order'}

  function TCustomManipulator.GetBackIndex: Integer;
  begin
    result := inherited;
    if Assigned(DropTarget) and DropTarget.Visible then
      inc(result); //reserve one more place at the bottom for DropTarget (if visible)
  end;

  procedure TCustomManipulator.SetDropTargetZorder;
  begin
    (* //NOT WORKING
    BeginUpdate;
    RemoveObject(DropTarget);
    InsertObject(GetBackIndex - 1, DropTarget);
    EndUpdate;
    *)
    if Assigned(DropTarget) and DropTarget.Visible then
      DropTarget.SendToBack;
  end;

  procedure TCustomManipulator.BringToFrontElseSendToBack(const Control: TControl);
  begin
    with Children do
      if IndexOf(Control) < Count - 1 then
        Control.BringToFront
      else
        Control.SendToBack;
  end;

  procedure TCustomManipulator.BringToFrontElseSendToBack(const Controls: TControlList);
  begin //TODO: why does it create some TObject here when you step with the debugger?
    BeginUpdate;

    TListEx<TControl>.ForEach(Controls,
      procedure (Control: TControl)
      begin
        BringToFrontElseSendToBack(Control);
      end
    );

    EndUpdate;
  end;

  procedure TCustomManipulator.BringToFrontElseSendToBackSelected;
  begin
    var TheSelected := AreaSelector.Selected;
    BringToFrontElseSendToBack(TheSelected);
    FreeAndNil(TheSelected);
  end;

  {$endregion}

  {$region 'Move'}

  procedure TCustomManipulator.MoveControl(const Control: TControl; const DX, DY: Single; const SkipAutoSize: Boolean = false);
  begin
    if Control.SubComponent then exit; //ignore any subcomponents like the DropTarget (or others added by descendents)

    BeginUpdate;

    with Control.Position do
    begin
      var NewX := X + DX;
      var NewY := Y + DY;

      if AutoSize or (not ClipChildren) or (InRange(NewX, 0, Width - 1) and InRange(NewY, 0, Height - 1)) then //allowing controls to move out of bounds if we're set to not clip them or if they're partially clipped (don't want them to totally disappear)
        Point := PointF(NewX, NewY)
      else
        Point := PointF( EnsureRange(NewX, 0, Width - Control.Width), EnsureRange(NewY, 0, Height - Control.Height) );
    end;

    if not SkipAutoSize then
      DoAutoSize;
    EndUpdate;
  end;

  procedure TCustomManipulator.MoveControls(const Controls: TControlList; const DX, DY: Single);
  begin
    if (DX <> 0) or (DY <> 0) then
      begin
      BeginUpdate;

      TListEx<TControl>.ForEach(Controls,
        procedure (Control: TControl)
        begin
          MoveControl(Control, DX, DY, true); //skip autosizing separately for each control
        end
      );

      DoAutoSize;
      EndUpdate;
      end;
  end;

  procedure TCustomManipulator.MoveControls(const DX, DY: Single);
  begin
    MoveControls(Controls, DX, DY);
  end;

  procedure TCustomManipulator.MoveSelected(const DX, DY: Single);
  begin
    if (DX <> 0) or (DY <> 0) then
      begin
      var TheSelected := AreaSelector.Selected;
      MoveControls(TheSelected, DX, DY);
      FreeAndNil(TheSelected);
      end;
  end;

  {$endregion}

  {$region 'Resize'}

  {$region 'Resize with ScaledDeltas'}

  procedure TCustomManipulator.ResizeControl(const Control: TControl; const SDW, SDH: Single; const SkipAutoSize: Boolean = false);
  begin
    if Control.SubComponent then exit; //ignore any subcomponents like the DropTarget (or others added by descendents)

    BeginUpdate;

    with Control.Size do
    begin
      var DW := SDW * Width; //SDW: scaled delta width
      var DH := SDH * Height; //SDH: scaled delta height
      var NewWidth := Width + DW;
      var NewHeight := Height + DH;

      //if AutoSize then //TODO: should we clamp Width/Height for child to always be inside parent?
        Size := TSizeF.Create(NewWidth, NewHeight)
      //else
        //Size := ...EnsureRange...
      ;

      Control.Position.Point := Control.Position.Point - PointF(DW/2, DH/2); //resize from center
    end;

    if not SkipAutoSize then
      DoAutoSize;

    EndUpdate;
  end;

  procedure TCustomManipulator.ResizeControls(const Controls: TControlList; const SDW, SDH: Single);
  begin
    if (SDW <> 0) or (SDH <> 0) then
    begin
      BeginUpdate;

      TListEx<TControl>.ForEach(Controls,
        procedure (Control: TControl)
        begin
          ResizeControl(Control, SDW, SDH, true); //skip autosizing separately for each control
        end
      );

      DoAutoSize;
      EndUpdate;
    end;
  end;

  procedure TCustomManipulator.ResizeControls(const SDW, SDH: Single);
  begin
    ResizeControls(Controls, SDW, SDH);
  end;

  procedure TCustomManipulator.ResizeSelected(const SDW, SDH: Single);
  begin
    if (SDW <> 0) or (SDH <> 0) then
    begin
      var TheSelected := AreaSelector.Selected;
      ResizeControls(TheSelected, SDW, SDH);
      FreeAndNil(TheSelected);
    end;
  end;

  {$endregion}

  {$region 'Resize with Bounds'}

  procedure TCustomManipulator.ResizeControl(const Control: TControl; const TheBounds: TRectF; const SkipAutoSize: Boolean = false);
  begin
    if Control.SubComponent then exit; //ignore any subcomponents like the DropTarget (or others added by descendents)

    BeginUpdate;

    with Control do
    begin
      //if AutoSize then //TODO: should we clamp Width/Height for child to always be inside parent?
        BoundsRect := TheBounds
      //else
        //Size.Size := ...EnsureRange...
      ;
    end;

    if not SkipAutoSize then
      DoAutoSize;

    EndUpdate;
  end;

  procedure TCustomManipulator.ResizeControls(const Controls: TControlList; const TheBounds: TRectF);
  begin
    BeginUpdate;

    TListEx<TControl>.ForEach(Controls,
      procedure (Control: TControl)
      begin
        ResizeControl(Control, TheBounds, true); //skip autosizing separately for each control
      end
    );

    DoAutoSize;
    EndUpdate;
  end;

  procedure TCustomManipulator.ResizeControls(const TheBounds: TRectF);
  begin
    ResizeControls(Controls, TheBounds);
  end;

  procedure TCustomManipulator.ResizeSelected(const TheBounds: TRectF);
  begin
    var TheSelected := AreaSelector.Selected;
    ResizeControls(TheSelected, TheBounds);
    FreeAndNil(TheSelected);
  end;

  {$endregion}

  {$endregion}

  {$region 'Rotate'}

  procedure TCustomManipulator.SetControlAngle(const Control: TControl; const Angle: Single);
  begin
    with (Control as IRotatedControl) do
      RotationAngle := Angle; //seems RotationAngle is protected, but since TControl implements IRotatedControl we can access that property through that interface
  end;

  procedure TCustomManipulator.RotateControl(const Control: TControl; const DAngle: Single; const SkipAutoSize: Boolean = false);
  begin
    if Control.SubComponent then exit; //ignore any subcomponents like the DropTarget (or others added by descendents)

    BeginUpdate;

    with (Control as IRotatedControl) do
      RotationAngle := RotationAngle + DAngle; //seems RotationAngle is protected, but since TControl implements IRotatedControl we can access that property through that interface

    if not SkipAutoSize then
      DoAutoSize;
    EndUpdate;
  end;

  procedure TCustomManipulator.RotateControls(const Controls: TControlList; const DAngle: Single);
  begin
    if (DAngle <>0) then
      begin
      BeginUpdate;

      TListEx<TControl>.ForEach(Controls,
        procedure (Control: TControl)
        begin
          try
            RotateControl(Control, DAngle); //skip autosizing separately for each control
          except //catch exceptions, in case any controls fail when you try to rotate them
            //NOP //TODO: do some error logging
          end;
        end
      );

      DoAutoSize; //TODO: is this needed? Do bounds change on rotation?
      EndUpdate;
      end;
  end;

  procedure TCustomManipulator.RotateControls(const DAngle: Single);
  begin
    RotateControls(Controls, DAngle);
  end;

  procedure TCustomManipulator.RotateSelected(const DAngle: Single);
  begin
    if (DAngle <> 0) then
      begin
      var TheSelected := AreaSelector.Selected;
      RotateControls(TheSelected, DAngle);
      FreeAndNil(TheSelected);
      end;
  end;

  {$endregion}

  {$endregion}

  procedure TCustomManipulator.DoAddObject(const AObject: TFmxObject);
  begin
    inherited;
    if Assigned(AreaSelector) then
      AreaSelector.BringToFront;
    if (AObject is TControl) then
      ApplyEditModeToChild(TControl(AObject));
  end;

  {$REGION 'PROPERTIES'}

  {$region 'AreaSelector'}

  procedure TCustomManipulator.SetAreaSelector(const Value: TAreaSelector);
  begin
    if Assigned(FAreaSelector) and (FAreaSelector.Owner = Self) then //don't free any externally provided AreaSelector that we didn't create
    begin
      FAreaSelector.Parent := nil; //unparent first, else it fails below
      FreeAndNil(FAreaSelector);
    end;
    FreeAndNil(FAreaSelector_SelectedControls);
    FAreaSelectorChanging := false;

    //Note: must not set parent for externally provided AreaSelector, setting it for internally created ones only at the constructor

    With Value do
    begin
      Stored := False; //don't store state
      SetSubComponent(true); //don't show in Designer for descendents

      ParentBounds := false; //CAN move outside of parent area

      Visible := FEditMode;
      Size.Size := TPointF.Zero;
      FLastAreaSelectorBounds := BoundsRect;

      GripSize := SELECTION_GRIP_SIZE; //TODO: should have some way to respond to AbsoluteScale change and adjust the Grip and the Border line respectively so that they don't show too big/fat
      BringToFront;

      OnlyFromTop := true; //TODO: add some keyboard modifier to area selector's MouseDown override or something for SHIFT key to override this temporarily (FOnlyFromTopOverride internal flag)

      OnTrack := HandleAreaSelectorTrack; //not using this since we have an extra point at the center for moving the contents of the selection (in contrast to just repositioning the selection)
      OnChange := HandleAreaSelectorChange; //this is called AFTER resize, but not when done explicitly
      OnMouseDown := HandleAreaSelectorMouseDown; //to detect double-click
    end;

    FAreaSelector := Value;
  end;

  {$region 'AutoSize'}

  procedure TCustomManipulator.SetAutoSize(const Value: Boolean);
  begin
    FAutoSize := Value;
    DoAutoSize; //will act only if FAutoSize
  end;

  function IsSelection(obj: TFmxObject): Boolean;
  begin
    Result := obj is TSelection;
  end;

  procedure TCustomManipulator.DoAutoSize;

    procedure SetControlsAlign(const List: TControlList; const TheAlignment: TAlignLayout);
    begin
      for var Control in List do
        if not ((Control is TDropTarget) or (Control is TRectangle) or (Control is TAreaSelector)) then //TODO: should have some info on which to excempt? or just do this for ones that have TAlignLayout.Scale? Or use some function that sets size without affecting children
          Control.Align := TheAlignment;
    end;

  begin
  (* //TODO: FAILS TRYING TO SET HUGE SIZE TO BOUNDSRECT
    if (FAutoSize) then
    begin
      BeginUpdate;

      //temporarily disable Align:=Scale setting of children and set it back again when done
      SetControlsAlign(Controls, TAlignLayout.None);

      var rect := GetChildrenRect;
      if Assigned(Parent) then
        rect := ConvertLocalRectTo(Parent as TControl, rect); //TODO: is there a chance the Parent is nil?

      with BoundsRect do
        if (rect.Left < Left) or (rect.Top < Top) or (rect.Right > Right) or (rect.Bottom > Bottom) then //only AutoSize to expand, never shrink down (else would disappear when there were no children)
          BoundsRect := rect; //TODO: seems to fail (probably should invoke later, not in the Track event of the PositionSelector)

      SetControlsAlign(Controls, TAlignLayout.Scale);

      EndUpdate;
    end;
  *)
  end;

  {$endregion}

  {$region 'DropTargetVisible'}

  function TCustomManipulator.IsDropTargetVisible: Boolean;
  begin
    result := DropTarget.Visible;
  end;

  procedure TCustomManipulator.SetDropTargetVisible(const Value: Boolean);
  begin
    with DropTarget do
    begin
      Visible := Value;
      //SendToBack; //always do when Visible changed
    end;
  end;

  {$endregion}

  {$region 'EditMode'}

  procedure TCustomManipulator.ApplyEditModeToChild(Control: TControl);
  begin
    if not Control.SubComponent then
      begin
      var NotEditing := not EditMode;
      Control.Enabled := NotEditing; //note this will show controls as semi-transparent
      //Control.HitTest := NotEditing; //TODO: seems "HitTest=false" eats up Double-Clicks, they don't propagate to parent control, need to fix
      //Control.SetDesign(EditMode, false);
      end;
  end;

  function TCustomManipulator.IsEditMode: Boolean;
  begin
    result := FEditMode;
  end;

  procedure TCustomManipulator.SetEditMode(const Value: Boolean);
  begin
    FEditMode := Value; //must do before calling ApplyEditModeToChild

    try
      //BeginUpdate; //TODO: see if it helps or causes text drawing issues

      if Assigned(FAreaSelector) then
        with FAreaSelector do
        begin
          Visible := Value; //Show or Hide selection UI (this will also hide the move control point)
          BringToFront; //always on top (need to do after setting Visible)
        end;

      DropTargetVisible := Value;

      TListEx<TControl>.ForEach( //TODO: should also do this action when adding new controls (so move the inner proc payload to separate method and call both here and after adding new control [have some InitControl that calls such sub-procs])
        Controls,
        ApplyEditModeToChild
      );

    finally
      //EndUpdate;
    end;
  end;

  {$endregion}

  {$region 'Proportional'}

  function TCustomManipulator.IsProportional: Boolean;
  begin
    result := AreaSelector.Proportional;
  end;

  procedure TCustomManipulator.SetProportional(Value: boolean);
  begin
    //if Value then Align := TAlignLayout.Fit else Align := TAlignLayout.Scale;
    AreaSelector.Proportional := Value; //TODO: if we reuse some passed to us AreaSelector should we have kept this value in local field and apply to it? (or use what that AreaSelector provides instead?)
  end;

  {$endregion}

  {$ENDREGION}

  {$ENDREGION}

  {$REGION 'EVENTS'}

  {$region 'AreaSelector'}

  procedure TCustomManipulator.HandleAreaSelectorMoving(Sender: TObject; const DX, DY: Single; out Canceled: Boolean);
  begin
    BeginUpdate;
    //Move all controls selected by the AreaSelector (that has just been moved)
    //MoveSelected(DX, DY); //this will also call DoAutoSize //NOT USED ANYMORE, using "HandleAreaSelectorTrack" instead
    Canceled := false;
    //after this, TSelectionPoint.HandleChangeTracking will move the SelectionArea, then fire OnParentMoved event (which is assigned to HandleAreaSelectorMoved of the manipulator)
  end;

  procedure TCustomManipulator.HandleAreaSelectorMoved(Sender: TObject; const DX, DY: Single);
  begin
    //at this point TSelectionPoint.HandleChangeTracking has moved the SelectionArea
    var SelectionPoint := TSelectionPoint(Sender); //assuming events are sent by TSelectionPoint
    with SelectionPoint do
      begin
      //var ParentPos := ParentControl.Position.Point;
      //var newX := ParentPos.X;
      //var newY := ParentPos.Y;

      //if AutoSize and (AreaSelector.SelectedCount > 0) then //Offset all controls (including this one) by the amount the selector got into negative coordinates (ONLY DOING IT FOR NEGATIVE COORDINATES)
        //MoveControls(TF.Iff<Single>(newX < 0, -newX, 0), TF.Iff<Single>(newY < 0, -newY, 0)); //this will also call DoAutoSize //there's also IfThen from System.Math, but those aren't marked as "Inline"
        //TODO: fix this: should only do for controls that moved into negative coordinates, not if the selector moved into such

      //PressedPosition := TPointF.Zero;
      Position.Point := TPointF.Zero;
      //Align := TAlignLayout.Center;
      end;
    EndUpdate;
  end;

  procedure TCustomManipulator.HandleAreaSelectorTrack(Sender: TObject);
  begin
    if not FAreaSelectorChanging then //just started resizing the AreaSelector, keep which controls were selected at that moment
    begin
      FreeAndNil(FAreaSelector_SelectedControls); //must do
      FAreaSelector_SelectedControls := AreaSelector.Selected; //note: must FreeAndNil at destructor (in case that gets called before user releases the mouse button while resizing AreaSelector) and at "HandleAreaSelectorChange"

      FLastAreaSelectorBounds := AreaSelector.BoundsRect; //don't do at HandleAreaSelectorChange, that does't seem to be called the first time when user drags and releases mouse from (0,0) area size to define the area selection //TODO: if using external AreaSelector should do coordinate conversion (it should provide property to set what control it's using as base and it should provide mapped bounds for that as special property)
      FLastPosition := FLastAreaSelectorBounds.Location; //we're reusing this field, also used in gestures

      FAreaSelectorChanging := true;
    end;

    if Assigned(FAreaSelector_SelectedControls) then
    begin
      var LSelectedArea := AreaSelector.BoundsRect; //TODO: if using external AreaSelector should do coordinate conversion (it should provide property to set what control it's using as base and it should provide mapped bounds for that as special property)

      //Not using ResizeSelected, that will select other controls while resizing

      if LSelectedArea.Size <> FLastAreaSelectorBounds.Size then //don't manually subtract and compare Width and Height to 0, TSizeF.NotEquals class operator function ends up using "SameValue" function from System.Types internally that has some error tolerance
      begin
        //var dSize := SelectedArea.Size - FLastAreaSelectorBounds.Size;
        //ResizeControls(FAreaSelector_SelectedControls, dSize.Width/FLastAreaSelectorBounds.Width, dSize.Height/FLastAreaSelectorBounds.Height); //scaling down the deltas by the respective initial width/height so that we scale up again when resizing each individual control by its current width/height inside its parent
        ResizeControls(FAreaSelector_SelectedControls, AreaSelector.SelectedArea); //resizing (distorting) to the new SelectedArea bounds, this is more stable and straightforward to implement
        //Note: Inflating by -SELECTION_GRIP_SIZE * 1.5 (via AreaSelector.SelectedArea property) to avoid strange issue where dragging from the part of the knob that is over the object does selection update
      end
      else
      begin
        var NewPosition := LSelectedArea.Location;
        var Offset := NewPosition - FLastPosition;
        FLastPosition := NewPosition;
        MoveControls(FAreaSelector_SelectedControls, Offset.X, Offset.Y);
      end;

      //Repaint; //make sure we get the resizing done and clear any paint artifacts //TODO: see if we need to repaint the Scene root instead
    end;
  end;

  procedure TCustomManipulator.HandleAreaSelectorChange(Sender: TObject);
  begin
    FAreaSelectorChanging := false;
    FreeAndNil(FAreaSelector_SelectedControls);
  end;

  procedure TCustomManipulator.HandleAreaSelectorMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  begin
    AreaSelector.Proportional := (ssShift in Shift); //if SHIFT key is pressed do proportional resizing of AreaSelection

    if (ssDouble in Shift) then //TODO: must do in EditMode (but has issue detecting it - anyway area select is hidden in non-Edit mode)
      BringToFrontElseSendToBackSelected;
  end;

  {$endregion}

  {$region 'Gestures'}
  //see https://docwiki.embarcadero.com/CodeExamples/Sydney/en/FMXInteractiveGestures_(Delphi)

  procedure TCustomManipulator.DoGesture(const EventInfo: TGestureEventInfo; var Handled: Boolean);
  begin
     inherited;

     if EventInfo.GestureID = igiPan then
      handlePan(EventInfo)
    else if EventInfo.GestureID = igiZoom then
      handleZoom(EventInfo)
    else if EventInfo.GestureID = igiRotate then
      handleRotate(EventInfo)
    else if EventInfo.GestureID = igiPressAndTap then
      handlePressAndTap(EventInfo);

    inherited;
  end;

  procedure TCustomManipulator.HandlePan(EventInfo: TGestureEventInfo);
  begin
    var LObj := ObjectAtLocalPoint(EventInfo.Location, false, true, false, false); //only checking the immediate children (ignoring SubComponents)
    if Assigned(LObj) then
    begin
      if (not (TInteractiveGestureFlag.gfBegin in EventInfo.Flags)) and
         (LObj.GetObject is TControl) then
        Movecontrol(TControl(LObj.GetObject),
          EventInfo.Location.X - FLastPosition.X, //DX
          EventInfo.Location.Y - FLastPosition.Y //DY
        );

      FLastPosition := EventInfo.Location;
    end;
  end;

  procedure TCustomManipulator.HandleRotate(eventInfo: TGestureEventInfo);
  begin
    var LObj := ObjectAtLocalPoint(EventInfo.Location, false, true, false, false); //only checking the immediate children (ignoring SubComponents)
    if Assigned(LObj) and (LObj.GetObject is TControl) then
      SetControlAngle(TControl(LObj.GetObject), RadToDeg(-EventInfo.Angle));
  end;

  procedure TCustomManipulator.HandleZoom(EventInfo: TGestureEventInfo);
  begin
    var LObj := ObjectAtLocalPoint(EventInfo.Location, false, true, false, false); //only checking the immediate children (ignoring SubComponents)
    if (not (TInteractiveGestureFlag.gfBegin in EventInfo.Flags)) and
       (LObj.GetObject is TControl) then
    begin
      var Control := TControl(LObj.GetObject);
      var dHalfDistance := (EventInfo.Distance - FLastDistance) / 2;
      Control.SetBounds(Position.X - dHalfDistance, Position.Y - dHalfDistance, Width + dHalfDistance, Height + dHalfDistance);
    end;

    FLastDIstance := EventInfo.Distance;
  end;

  procedure TCustomManipulator.HandlePressAndTap(EventInfo: TGestureEventInfo);
  begin
    var LObj := ObjectAtLocalPoint(EventInfo.Location, false, true, false, false); //only checking the immediate children (ignoring SubComponents)
    //TODO: delete object?
  end;

  {$endregion}

  {$region 'Mouse'}

  procedure TCustomManipulator.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  begin
    FMouseShift := Shift; //TODO: remove if Delphi fixes related bug (more at FMouseShift definition) //Note that MouseUp fires before MouseClick so we do need to have this in MouseDown

    inherited; //needed for event handlers to be fired (e.g. at ancestors)

    if {((AreaSelector.Parent <> Self) and not (Parent is TCustomManipulator)) and }(not EditMode) then
    begin
      //FLastPosition := PointF(X, Y); //TODO: fix logic to move around non-Locked objects via mousedown+mousemove (also see Pan action at gestures section)
      exit;
    end;

    if (ssLeft in Shift) then
      begin
      BeginUpdate;

      Capture; //start mouse events capturing

      var p := PointF(X, Y);
      FDragStartLocation := p;

      with AreaSelector do
      begin
        Visible := false;
        Position.Point := p;
        Size.Size := TSizeF.Create(0 ,0); //there's no TSizeF.Zero (like TPointF.Zero)
        FAreaSelectorChanging := false;
      end;

      EndUpdate;
      end;
  end;

  procedure TCustomManipulator.MouseMove(Shift: TShiftState; X, Y: Single);
  begin
    inherited; //needed so that FMX will know this wasn't a MouseClick (that we did drag between MouseDown and MouseUp) and for event handlers to be fired (e.g. at ancestors)

    if {((AreaSelector.Parent <> Self) and not (Parent is TCustomManipulator)) and }(not EditMode) then
    begin
  { //TODO: fix logic to move around non-Locked objects via mousedown+mousemove (also see Pan action at gestures section) - need to know that we are dragging, e.g. check ssLeft in Shift
      var Pos := PointF(X, Y);
      var LObj := ObjectAtLocalPoint(Pos, false, true, false, false); //only checking the immediate children (ignoring SubComponents)
      if Assigned(LObj) then
      begin
        if (LObj.GetObject is TControl) then
        begin
          var Control := TControl(LObj.GetObject);
          if not Control.Locked then
            Movecontrol(Control,
              X - FLastPosition.X, //DX
              Y - FLastPosition.Y //DY
            );
        end;

        FLastPosition := Pos;
      end;
  }
      exit;
    end;

    if (ssLeft in Shift) then
    begin
      FDragging := true;

      with AreaSelector do
      begin
        var LX: Single := FDragStartLocation.X; //Delphi 11 compiler issue, gives below at call to Order function error "E2033 Types of actual and formal var parameters must be identical if we skip ": Single", even though it is of type Single
        Order(LX, X);

        var LY: Single := FDragStartLocation.Y; //Delphi 11 compiler issue, gives "E2033 Types of actual and formal var parameters must be identical if we skip ": Single", even though it is of type Single
        Order(LY, Y);

        BoundsRect := RectF(LX, LY, X, Y);
        Visible := true;
        BringToFront; //need to do this when visibility changes
      end;
    end;
  end;

  procedure TCustomManipulator.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  begin
    Shift := FMouseShift; //TODO: remove if Delphi fixes related bug (more at FMouseShift definition)
    inherited; //needed for event handlers to be fired (e.g. at ancestors)

    if {((AreaSelector.Parent <> Self) and not (Parent is TCustomManipulator)) and }(not EditMode) then exit;

    if (ssLeft in Shift) then
      begin
      FDragging := false;
      ReleaseCapture; //stop mouse events capturing
      end;
  end;

  procedure TCustomManipulator.MouseClick(Button: TMouseButton; Shift: TShiftState; X, Y: Single);
  begin
    Shift := FMouseShift; //TODO: remove if Delphi fixes related bug (more at FMouseShift definition)
    inherited; //needed for event handlers to be fired (e.g. at ancestors)

    //if FDragging then exit; //make sure a MouseClick doesn't occur if we've moved the mouse //TODO: was supposed to fix an area drag that had bottom-right onto some object (that results in thinking that object was clicked and selecting it instead by changing selection area bounds to wrap it), but cause click-to-select to not work anymore (seems MouseMove is always called, setting fDragging to true)

    if {((AreaSelector.Parent <> Self) and not (Parent is TCustomManipulator)) and }(not EditMode) then exit;

    //TODO: if we allow using an external AreaSelector, should use ObjectAtLocalPoint of whatever object is assigned to it to "work on" (instead of doing selections on the Root manipulator if there's an hierarchy of them)
    if (ssLeft in Shift) then
    begin //TODO: the ObjectAtLocalPoint and the check for the GetObject type etc. and the casting to TControl are repeated code, make a function
      var LObj := ObjectAtLocalPoint(PointF(X, Y), false, true, false, false); //only checking the immediate children (ignoring SubComponents)
      if Assigned(LObj) and (LObj.GetObject is TControl) then
        with AreaSelector do
        begin
          var rect := TControl(Parent).AbsoluteToLocal(TControl(LObj.GetObject).AbsoluteRect); //TODO: doesn't solve the case of children with negative scales
          var d := SELECTION_GRIP_SIZE/1.3;
          rect.Inflate(d, d, d, d); //Inflating by SELECTION_GRIP_SIZE * 1.5 to avoid strange issue where dragging from the part of the knob that is over the object does selection update
          BoundsRect := rect;
          FAreaSelectorChanging := false;
          Visible := true;
          BringToFront; //need to do this when visibility changes
        end;
    end;
  end;

  procedure TCustomManipulator.MouseWheel(Shift: TShiftState; WheelDelta: Integer; var Handled: Boolean);

    procedure DoAltMouseWheel;
    begin
      var ScreenMousePos := Screen.MousePos;
      var LObj := ObjectAtPoint(ScreenMousePos, false, true, false, false); //only checking the immediate children which are not subcomponents

      var Control := TControl(Self); //if not child under mouse cursor, act upon ourselves
      if Assigned(LObj) then
      begin
        Control := TControl(LObj.GetObject);
        if Control.SubComponent then exit; //redundant safety check: ignore any subcomponents like the DropTarget (or others added by descendents) in case the parameter we passed to ObjectAtPoint failed somehow
      end;

      var zoom_center := Control.ScreenToLocal(ScreenMousePos); //use mouse cursor as center

      var new_scale : Single;
      if WheelDelta >= 0
        then new_scale := (1 + (WheelDelta / 120)/5)
        else new_scale := 1 / (1 - (WheelDelta / 120)/5);

      //BeginUpdate; //TODO: would it be enough to do Control.BeginUpdate/Control.EndUpdate instead?

      if (ssShift in Shift) then //ALT+SHIFT+mousewheel to rescale
      begin
        Control.Scale.X := new_scale;
        Control.Scale.Y := new_scale;
        //correction for zoom center position
        Control.Position.Point := Control.Position.Point + zoom_center * (1-new_scale); //TODO: not working correctly (?)
      end
      else //ALT+mousewheel to resize
      begin
        var newSize := TSizeF.Create(Control.Width * new_scale, Control.Height * new_scale); //TODO: maybe rescale instead of resize to preserve quality? (see SHIFT key above)
        var newPos := Control.Position.Point + zoom_center * (1-new_scale); //correction for zoom center position
        Control.BoundsRect := TRectF.Create(newPos, newSize.Width, newSize.Height); //TODO: does this take in mind Scale?
      end; //adapted from https://stackoverflow.com/a/66049562/903783 //Note: need to use BoundsRect, not Size, else control's children that are set to use "Align=Scale" seem to become larger when object shrinks and vice-versa instead of following its change

      //EndUpdate;

      Handled := true; //needed for parent containers to not scroll
      exit;
    end;

  begin
    inherited; //needed for event handlers to be fired (e.g. at ancestors)

    (*
    if (ssXX in Shift) then
    begin
      //TODO: should tell any ScrollBox parent to pan horizontally
      exit;
    end;
    *)

    if EditMode and (ssAlt in Shift) then
      DoAltMouseWheel;
  end;

  {$endregion}

  {$region 'DragDrop'}

  procedure TCustomManipulator.DragEnter(const Data: TDragObject; const Point: TPointF);
  begin
    inherited;

    if EditMode then
      DropTarget.HitTest := true;
  end;

  procedure TCustomManipulator.DragLeave;
  begin
    inherited;

    //DropTarget.HitTest := false; //always do just in case it was missed //NOT DOING, CAUSES FLASHING AND CONTINUOUS ENABLE-DISABLE OF DROP OPERATION (PROBABLY FMX BUG) - COULD HAVE KEPT DROPTARGET WITH HITTEST TRUE ANYWAY
  end;

  procedure TCustomManipulator.DropTargetDragOver(Sender: TObject; const Data: TDragObject; const Point: TPointF; var Operation: TDragOperation);
  begin
    if EditMode then
      Operation := TDragOperation.Copy;
  end;

  procedure TCustomManipulator.DropTargetDropped(Sender: TObject; const Data: TDragObject; const Point: TPointF);
  begin
    if EditMode then
      DropTargetDropped(Data.Files);
  end;

  procedure TCustomManipulator.DropTargetDropped(const Filepaths: array of string);
  begin
    //NOP (override at descendents)
  end;

  {$endregion}

  {$ENDREGION}

  {$ENDREGION .................................................................}

  {$REGION 'Registration' -----------------------------------------------------}

  procedure RegisterSerializationClasses;
  begin
    RegisterFmxClasses([TCustomManipulator], [TFrame]); //register for persistence (in case they're used standalone)
  end;

  {$ENDREGION .................................................................}

initialization
  RegisterSerializationClasses; //don't call Register here, it's called by the IDE automatically on a package installation (fails at runtime)

end.
