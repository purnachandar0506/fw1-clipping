	<cfset selectedColumnList="">
	<cfinvoke component="#LMComponentPath#.admin.component.Utils" method="getCustomReportColumns" returnvariable="selectedColumnList">
		<cfinvokeargument name="selreportType" value="Asset">	
		<cfinvokeargument name="customReport" value="#customReport#">	 
		<cfinvokeargument name="datasource" value="#LMDB#">
		<cfinvokeargument name="personCode" value="#xuid#">
	</cfinvoke>
	 
    <cfquery name="GetSearchCount" datasource="#LMDB#">
     Select count(*) as C from
     (Select distinct E.*,EN.[Name] as LabName,isnull(EP.Name,'Unknown') as ownername,isnull(MapID,0) as MapID,isnull(M.Name,'NOT ON ANY MAP') as MapName,isnull(M.Name,'ZZZZZZ') as dummy,
      I.F1,I.F2,I.F3,I.F4,I.F5,I.F6,I.F7,I.F8,I.F9,I.F10,
      I.F11,I.F12,I.F13,I.F14,I.F15,I.F16,I.F17,I.F18,I.F19,I.F20,
      I.F21,I.F22,I.F23,I.F24,I.F25
      <cfif CapexData is 1> ,C.*  <!--- add CAPEX info ---></cfif>
	  ,isnull(ST.Reservable,isnull(ST.Reservable,1)) as Reservable <!--- Use general state, only if not found: use state for that lab --->
	  ,isnull(ST.Operational,isnull(ST.Operational,1)) as Operational <!--- Use general state, only if not found: use state for that lab --->
      from LabmanElement E
      Left Join LabmanState ST on E.Status=ST.State and (ST.LabID=E.LabID or ST.LabID=0)
      Left Join LabmanElementInfo I on E.ID=I.ElementID and I.Type=''
      Left Join labman.dbo.Persons EP on E.Owner=EP.Person
      Left Join LabmanMapElement EE on E.ID=EE.ElementID
      Left Join LabmanMap M on EE.MapID=M.ID
      Left Join LabmanLab EN on E.LabID=EN.[ID]
      <cfif CapexData is 1>  <!--- Link CAPEX info --->
        Left Join vElementCAPEXInfo C on E.ID=C.ElementID
      </cfif>
      where isnull(E.Assetnumber,'')<>'NA' and isnull(E.AssetNumber,'')<>'noasset'
		 <cfif Labs is not "%">and E.LabID in (#labs#)</cfif>
		 and #PreserveSingleQuotes(QS)#) A
    </cfquery>
    <cfset RecCount=GetSearchCount.C>  
    <cfif RecCount GT 0>
       <cfquery name="GetSearch" datasource="#LMDB#">
        Select distinct
         <cfif not isdefined('ExcelOutput')>top #NrRows#<cfelse>top 50000</cfif>
         E.*,EN.[Name] as LabName,isnull(EN.SwitchOnOffLink,'') as EcoServerLink,isnull(EP.Name,'Unknown') as ownername,isnull(MapID,0) as MapID,isnull(M.Name,'NOT ON ANY MAP') as MapName,isnull(M.Name,'ZZZZZZ') as dummy,
         I.F1,I.F2,I.F3,I.F4,I.F5,I.F6,I.F7,I.F8,I.F9,I.F10,
         I.F11,I.F12,I.F13,I.F14,I.F15,I.F16,I.F17,I.F18,I.F19,I.F20,
         I.F21,I.F22,I.F23,I.F24,I.F25
         <cfif CapexData is 1> ,C.*  <!--- add CAPEX info ---></cfif>
         ,isnull(STG.Reservable,isnull(ST.Reservable,1)) as Reservable <!--- Use general state, only if not found: use state for that lab --->
         ,isnull(STG.Operational,isnull(ST.Operational,1)) as Operational <!--- Use general state, only if not found: use state for that lab --->
		 ,isnull(lm.xPowerState, 0) xPowerState
         from LabmanElement E
		 Left Join LabmanState STG on E.Status=STG.State and STG.LabID=0 <!--- KV: State can exist for Lab=0: general state --->
		 Left Join LabmanState ST on E.Status=ST.State and ST.LabID=E.LabID <!--- KV: State can exist for that lab --->
         Left Join LabmanElementInfo I on E.ID=I.ElementID and I.Type=''
         Left Join labman.dbo.Persons EP on E.Owner=EP.Person
         Left Join LabmanMapElement EE on E.ID=EE.ElementID
         Left Join LabmanMap M on EE.MapID=M.ID
         Left Join LabmanLab EN on E.LabID=EN.[ID]
		 Left Join LabmanPowerManagement lm on E.id = lm.elementid
         <cfif not isdefined('ExcelOutput') and StartRow GT 1>
         Left Join
          (
           Select top #evaluate(StartRow-1)# E.LabID, E.Name
            from LabmanElement E
            <cfif FindNoCase("I.",QS) GT 0>Left Join LabmanElementInfo I on E.ID=I.ElementID and I.Type=''</cfif>
            Left Join LabmanMapElement EE on E.ID=EE.ElementID
            Left Join LabmanMap M on EE.MapID=M.ID
            where <cfif Labs is not "%">E.LabID in (#labs#) and</cfif> #PreserveSingleQuotes(QS)#
            order by <cfif SortOn is not ""><cfif SortOn is "EP.Name">isnull(EP.Name,'Unknown'),<cfelse>#SortOn#,</cfif></cfif><cfif Left(SortOn,8) is not "E.[Type]">E.[Type],</cfif><cfif Left(SortOn,8) is not "E.[Name]">E.[Name],</cfif>isnull(M.Name,'ZZZZZZ')
          ) X on E.LabID=X.LabID and E.Name=X.Name
         </cfif>
         <cfif CapexData is 1>  <!--- Link CAPEX info --->
           Left Join vElementCAPEXInfo C on E.ID=C.ElementID
         </cfif>
	      where isnull(E.Assetnumber,'')<>'NA' and isnull(E.AssetNumber,'')<>'noasset'
			<cfif Labs is not "%">and E.LabID in (#labs#)</cfif>
			and #PreserveSingleQuotes(QS)#
         <cfif not isdefined('ExcelOutput') and StartRow GT 1>and X.Name is null</cfif>
         order by <cfif SortOn is not ""><cfif SortOn is "EP.Name">isnull(EP.Name,'Unknown'),<cfelse>#SortOn#,</cfif></cfif><cfif Left(SortOn,8) is not "E.[Type]">E.[Type],</cfif><cfif Left(SortOn,8) is not "E.[Name]">E.[Name],</cfif>isnull(M.Name,'ZZZZZZ')
       </cfquery>
       <cfif CapexData is 1>
         <cfquery name="GetSearchCAPEXTotals" datasource="#LMDB#">
          Select sum(AccumulatedOrdDepreciation) as TotalAccumulatedOrdDepreciation,
           Sum(AcquisitionValue) as TotalAcquisitionValue,
           Sum(PlannedOrdDepreciation) as TotalPlannedOrdDepreciation,
           Sum(CurrentBookValue) as TotalCurrentBookvalue,
           Sum(BookvalBeginFiscYear) as TotalBookvalBeginFiscYear,
           Sum(BookvalEndFiscYear) as TotalBookvalEndFiscYear
		   ,currency
          from LabmanElement E
		  Left Join LabmanState STG on E.Status=STG.State and STG.LabID=0 <!--- KV: State can exist for Lab=0: general state --->
		  Left Join LabmanState ST on E.Status=ST.State and ST.LabID=E.LabID <!--- KV: State can exist for that lab --->
          Left Join LabmanElementInfo I on E.ID=I.ElementID and I.Type=''
          Left Join labman.dbo.Persons EP on E.Owner=EP.Person
          Left Join LabmanMapElement EE on E.ID=EE.ElementID
          Left Join LabmanMap M on EE.MapID=M.ID
          Left Join LabmanLab EN on E.LabID=EN.[ID]
          Left Join vElementCAPEXInfo C on E.ID=C.ElementID
          where <cfif Labs is not "%">E.LabID in (#labs#) and</cfif> #PreserveSingleQuotes(QS)#
			 and currency is not null
		     group by currency
         </cfquery>
       </cfif>  
    </cfif>  
