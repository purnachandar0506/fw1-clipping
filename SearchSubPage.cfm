<cfimport prefix="lm" taglib="CustomTags">
<cfparam name="PrevPage" default="">
<cfparam name="Labs" default="#lab#">
<cfparam name="customReport" default="">
<cfparam name="CapexData" default="0">
<cfparam name="SuperSearch" default="0">
<cfparam name="transferID" default="">
<cfparam name="receiverUID" default="">
<cfparam name="SortOn" default="">
<cfparam name="ReserveHours" default="0">
<cfparam name="selectedColumnList" default="">
<cfset legendList = "(Setup),Purchase Order Number,Remarks,User Remark (USER),Import Date,Last Scanned Date,Property,Last CalibrationDate,Maintenance Contract Remark,Lab Specific Field 1,Lab Specific Field 2,Lab Specific Field 3,Lab Specific Field 4,Part Number,Element_Name,Licence_Key,OS_SP,For Sale Startdate">
<cfset legendFlist = "F1,F2,F3,F4,F5,F6,F7,F8,F9,F10,F11,F12,F13,F14,F15,F16,F17,F18">
<cfset QFieldNameist = "ProductCode,Description,Brand,Application,AssetNumber,SerialNumber,IPAddresses,site,location,platform,box,EquipmentType,xCommercialStatus,SM_Type,Units,Depth,Width,Weight,PowerOnType,PowerITF_Type,AutoPowerUp,PowerITF_ID,RepairContractor,OwnerName,OwnerOrg,MaxUsers,MaxReservDuration">
<cfset flabelList="Item Code,Long Description,Brand,Application,AssetNumber,SerialNumber,IP Addresses,Site,Location,(Platform),(Box),Equipment Type,Commercial Status,SM TYPE,Units,Depth,Width,Weight,Element Power on Type,Power ITF Type,Auto Power Up,Power ITF ID,Repair Contractor,Owner of element,Owner Org.,Max. Users,Max.Reserv. Days">
<cfset fnameList = "E.[ProductCode],E.[Description],E.[Brand],E.[Application],AssetNumber,SerialNumber,IPAddresses,E.Site,E.[Location],E.Platform,E.box,E.EquipmentType,E.xCommercialStatus,E.SM_Type,E.Units,E.Depth,E.Width,E.Weight,E.PowerOnType,E.PowerITF_Type,E.AutoPowerUp,E.PowerITF_ID,E.RepairContractor,EP.Name,OwnerOrg,MaxUsers,MaxReservDuration">

<cfif not isdefined("ExcelOutput")>
	<cfinclude template="bubbleInfoPowerJS.cfm" >
</cfif>
<cfif PROF["IsAdministrator"] is 0>
	<cfset QS="#QS# and isnull(E.Name,'') not like '%(restricted)'">
</cfif>
<!--- Region: George added @2014-9-10 for 2014ER4831 --->
<cfif not listContains(PROF["AccessRights"], "Read_Full_Asset")>
	<cfset QS="#QS# and isnull(E.Description,'') not like '%(confidential)'">
</cfif>
<!--- Region end --->
<!---Region: Added by George @2012-5-22 for 2012R1.LM1202024 --->
<cfif AT is "Allocation">
	<cfset HourlyUseForSearch = 1>
<cfelse>
	<cfset HourlyUseForSearch = 0>
</cfif>
<cfquery name="getLabHourlyUse" datasource="#LMDB#">
	select distinct IsNull(HourlyUse,0) as HourlyUse from LabmanLab where IsNull(HourlyUse,0)=1 and <cfif Labs is "%">ID=#xLID#<cfelse>ID in (#Labs#)</cfif>
</cfquery>
<cfif getLabHourlyUse.RecordCount gt 0>
	<cfset HourlyUseForSearch = 1>
</cfif>
<!--- end --->
<!---Region: Modified by George @2012-5-7 for 2012R1.LM1202024 --->
<cfquery name="getUserTimeZone" datasource="#LMDB#">
	select p.person, p.name, isnull(TimeZone, 'UTC') as TimeZone, isnull(OffsetFromUTC, 0) as OffsetUTC
	from Labman.dbo.Persons as p
	where person=#val(xUID)#
</cfquery>
<cfset tz=createObject("component","#LMComponentPath#.admin.component.timeZone")>
<!--- end --->
<cfset MyOwner="">
<cfif isdefined("Requestor")>
	<cfset MyOwner=val(Requestor)>
<cfelseif isdefined("Form.Requestor")>
	<cfset MyOwner=Form.Requestor>
</cfif> 
<cfif AT is "Asset">
	<cfinclude template="SearchAsset.cfm">
<cfelseif AT is "IPAddress">
	<cfinclude template="SearchIP.cfm">
<cfelseif AT is "SPARE">
	<cfinclude template="SearchSpare.cfm">
<cfelseif AT is "Element">
	<cfinclude template="SearchElement.cfm">
<cfelseif AT is "Planning">
	<cfinclude template="SearchPlanning.cfm">
<!--- Region: Added by George @2012-5-23 for 2012R1.LM1201005 --->
<cfelseif AT is "Allocation">
	<cfinclude template="SearchAllocation.cfm">
<!--- Region end --->
</cfif>
<cfif not isdefined("CheckUserDefinedFixedField")>
	<cfinclude template="CheckUserDefinedFixedField.cfm"> 
</cfif>
<cfif RecCount is 0>
	<cfif QSDesc is not "">
		<br><font color="red"><b>Nothing found with these criteria: <cfoutput>#QSDesc#</cfoutput></b></font>
		<cfif AT is "Planning">
			<br><font color="blue"><b>Please note that elements belonging to a platform are not shown in this search.
			<br>Only the mother platform element is shown since only the complete platform can be reserved.</b></font>
		</cfif>
	</cfif>  
<cfelse>
	<cfif AT is "Planning">
		<cfset ShedStart=GetMinMax.FirstStart>
		<cfset ShedEnd=GetMinMax.LastEnd>
		<cfset GraphViewOnly=1>
		<cfif not isdefined('ExcelOutput')>
<!--->			<div style="width:100%;height:400;overflow-x:auto;overflow-y:auto"><--->
		    <cfinclude template="Shedule.cfm">
		</cfif>
	</cfif>
	<!---     <cfif ThisTemplate is "ReserveWizard.cfm" or ThisTemplate is "AcceptReservation.cfm" or ThisTemplate is "EditShedule.cfm"> --->
	<cfif AT is "Planning" and not isdefined('ExcelOutput')>
	
		<cfif ThisTemplate is "Search.cfm">
			</form>
			<cfset SearchSIDs="">
			<cfloop query="GetSearch">
				<cfif (Pending is 1 OR Pending is 2 OR Pending IS 3 OR Pending IS 4) and (PROF["IsAdministrator"] is 1 or Owner is xUID or FindNoCase(",#Owner#,",",#Persons_Delegate_O#,") GT 0)>
					<cfset SearchSIDs="#SearchSIDs##SheduleID#,">
				</cfif>
			</cfloop>
			<cfif SearchSIDs is not "">
				<cfset SearchSIDs=Left(SearchSIDs,Len(SearchSIDs)-1)>
			</cfif>
		</cfif>
	
		<form onsubmit="return(validateAccept());" name="AcceptShedule" method="post" action="<cfoutput><cfif ThisTemplate is "ReserveWizard.cfm" or ThisTemplate is "EditShedule.cfm">ReserveWizard.cfm?User=#MyOwner#<cfelseif ThisTemplate is "ReserveUpload.cfm">ReserveWizard.cfm?User=#xUID#<cfelseif ThisTemplate is "Search.cfm">AcceptReservation.cfm?SheduleID=#SearchSIDs#<cfif isDefined('transferTo') AND len('transferTo')>&transferTo=#transferTo#</cfif> <cfelse>AcceptReservation.cfm?SheduleID=#URL.SheduleID#<cfif isDefined('transferTo') AND len('transferTo')>&transferTo=#transferTo#</cfif></cfif></cfoutput>">
		<cfoutput>
		<input type="hidden" name="PrevPage" value="#PrevPage#">
		<cfif isdefined("ReserveHours")>
			<input type="hidden" name="ReserveHours" value="#ReserveHours#">
		</cfif>
		</cfoutput>
	</cfif>

	<cfset UsedColumns="">
	<cfloop INDEX="j" LIST="#MyColumnList#">
		<cfoutput query="GetElementInfoLegend">
			<cfset result = checkCF(evaluate(j))>
<!--- Region: George added @2013-2-8 for 2013ER#LM1210004 --->
			<cfif j is "LabID" or result.isFixedField>
				<cfset FNm="">
			<cfelseif isdefined("SemiFixedFields") and StructKeyExists(SemiFixedFields, j)>
				<cfset FNm=SemiFixedFields[j]>
			<cfelse>
				<cfset FNm=evaluate(j)>
			</cfif>
<!--- Region end --->
			<!---cfif j is not "LabID" and result.isFixedField is false and j is not "Type" and evaluate(j) is not "Subtype" and evaluate(j) is not "Brand" and Replace(evaluate(j),' ','') is not "ProductName" and Replace(evaluate(j),' ','') is not "ShortDescription" and Replace(evaluate(j),' ','') is not "ProductCode" and Replace(evaluate(j),' ','') is not "ItemCode" and Replace(evaluate(j),' ','') is not "Application" and evaluate(j) is not "Owner" and Replace(evaluate(j)," ","") is not "OldKey" and evaluate(j) is not "Status" --->
			<cfif FNm is not "">
				<cfif Findnocase("(restricted)",FNm) EQ 0 or PROF["IsAdministrator"] is 1>
					<cfset UsedColumns="#UsedColumns##j#,">
				</cfif>
			</cfif>
		</cfoutput>
	</cfloop>

	<cfif UsedColumns is ",">
		<cfset UsedColumns="">
	<cfelseif Right(UsedColumns,1) is ",">
		<cfset UsedColumns=Left(UsedColumns,Len(UsedColumns)-1)>
	</cfif>

<!-- Added by Tony -->
<cfif (AT is "Element" or AT is "Planning") and not isdefined('ExcelOutput')> <!--- KV@20170131: This Cart code is to be excluded for Excel output --->
	<script language="javascript" type="text/javascript">
	
			function addToCart(){
				var getElementsByClassName = function(searchClass,node,tag) {
					if(document.getElementsByClassName){
						return  document.getElementsByClassName(searchClass)
					}else{    
						node = node || document;
						tag = tag || '*';
						var returnElements = []
						var els =  (tag === "*" && node.all)? node.all : node.getElementsByTagName(tag);
						var i = els.length;
						searchClass = searchClass.replace(/\-/g, "\\-");
						var pattern = new RegExp("(^|\\s)"+searchClass+"(\\s|$)");
						while(--i >= 0){
							if (pattern.test(els[i].className) ) {
								returnElements.push(els[i]);
							}
						}
						return returnElements;
					}
				}
				var operations = getElementsByClassName('operation');

				var flag = 0;
				var count = 0;
					for (var i = 0; i < operations.length; i++) {
						var operation = operations[i];
						if (operation.checked == true) {	//checkbox is checked
							var eid = operation.value;
							count++;
							$.ajax({
									type: "POST",
									url: "MyCartInsertToDB.cfm",
									data:
									{
										Person:<cfoutput>#val(xUID)#</cfoutput>,
										LabID:<cfoutput>#lab#</cfoutput>,
										ElementID: eid
									},
									async: false,
									success: function(){

									},
								
									error: function(){
										flag++;
									}
								});
						} 
					}
					if (count <= 0)
						return false;
					if(flag == count ){
		            alert("The selected items have already been added to your cart");
		          	}else{
		            	alert("The selected items are added to your cart");
		         	 }

					//uncheck which were checked
					for (var i = 0; i < operations.length; i++){
						var operation = operations[i];
						operation.checked = false;
					} 
			}
	
	</script>
<!--->
<style>
	#cartOperation{
		width:140px;
		float:right;
		margin-right: 10px;
	}
	
	#cartOperation>a{
		text-decoration: none;
		display:block;
		color:blue;
		font-weight:bold;
		width:140px;
	}
	#cartOperation>a>div{
		border: 2px solid blue;
		width:140px;
		height:30px;
		margin-bottom: 10px;
		padding-right: 5px;
	}
	#cartOperation>a>div>.label{
		display:inline-block;
		vertical-align:middle;
		text-align:center;
		width:90px;
	}
	#cartOperation>a>div>span>img{
		display:inline-block;
		vertical-align:middle;
		height:30px;
		width:30px;	
	}
</style>
<--->
<cfif HTitle is not "Reserve WIZARD">
	<div align="right" width="200px" id="cartOperation" style="width:140px;float:right;margin-right: 10px;">
		<a href="MyCart.cfm?LabID=<cfoutput>#GetSearch.LabID#</cfoutput>" style="text-decoration: none;display:block;color:blue;font-weight:bold;width:140px; height:30px;cursor:pointer;">
			<div style="border: 2px solid blue;width:140px;height:30px;padding-right: 5px;cursor:pointer;">
				<span class="label" style="display:inline-block;vertical-align:middle;text-align:center;width:90px;">View Cart</span>
				<span><img src="images/cart.png" style="display:inline-block;vertical-align:middle;height:30px;width:30px;	"></span>
			</div>
		</a><br>
		<a href="javascript:void(0)" onclick="return addToCart()" style="text-decoration: none;display:block;color:blue;font-weight:bold;width:140px;height:30px;cursor:pointer;">
			<div style="border: 2px solid blue;width:140px;height:30px;padding-right: 5px;cursor:pointer;">
				<span class="label" style="display:inline-block;vertical-align:middle;text-align:center;width:90px;">Add to Cart</span>
				<span><img src="images/cart_down.png" style="display:inline-block;vertical-align:middle;height:30px;width:30px;	"></span>
			</div>
		</a>
		
	</div>
</cfif>
</cfif>
<!-- Region end -->


<!---     <table border="0"> --->
	<cfset FormName="searchform">
	<cfif ThisTemplate is not "ReserveUpload.cfm">
		<cfif Supersearch is 0 and Printerfriendly is 1><!--- <tr><td> --->
			<font color="blue"><b><cfoutput>Search in LAB #GetSearch.LabName#<cfif InstanceType is not "Real"> (#InstanceType# labman)</cfif></cfoutput>:</b><br></font>
		</cfif>
		<font color="blue"><b><cfoutput>#RecCount#</cfoutput> rows found using criteria: <cfoutput>#QSDesc#</cfoutput></b><br>
		<cfif isdefined("MyMnem")> <!--- KV @20150630 req. of Paul to show not found mnem using "in" --->
			<cfif MyMnem is not "">
				<cfif MFC is "in">
					<cfset ListA=Ucase(Replace(MyMnemList,"'","","All"))>
					<cfset ListB="#Ucase(ValueList(GetSearch.Name,","))#,#UCase(ValueList(GetSearch.ProductCode,","))#">
					<cfinvoke component="#LMComponentPath#.admin.component.Utils"
						method="listAnotinB" returnvariable="ListDifference">
						<cfinvokeargument name="ListA" value="#ListA#">	
						<cfinvokeargument name="ListB" value="#ListB#">	
						>
					</cfinvoke>
					<cfif ListDifference is not "">
						<font color="red"><cfoutput>FYI: These elements were not found: #ListDifference#</cfoutput></font><br>
					</cfif>
				</cfif>
			</cfif>			
		</cfif> <!--- KV @20150630 END --->
		<cfif CapexData is 1 and isdefined("GetSearchCAPEXTotals.recordcount")>
			<cfoutput>Your selection resulted in Tot.Acc.Ord.Depreciation=#val(GetSearchCAPEXTotals.TotalAccumulatedOrdDepreciation)# #GetSearchCAPEXTotals.currency#;
				Tot.Plan.Ord.Depreciation=#val(GetSearchCAPEXTotals.TotalPlannedOrdDepreciation)# #GetSearchCAPEXTotals.currency#;
				Tot.Acquisition Value=#val(GetSearchCAPEXTotals.TotalAcquisitionValue)# #GetSearchCAPEXTotals.currency#;
				Tot.Current Bookvalue=#val(GetSearchCAPEXTotals.TotalCurrentBookvalue)# #GetSearchCAPEXTotals.currency#;
				<!--- Tot.Bookval Begin Fisc.Year=#val(GetSearchCAPEXTotals.TotalBookvalBeginFiscYear)#;
				Tot.Bookval End Fisc.Year=#val(GetSearchCAPEXTotals.TotalBookvalEndFiscYear)# ---><br>
			</cfoutput>
		</cfif>
		</font>
		
		<cfif not isdefined('ExcelOutput') and ThisTemplate is not "ReserveWizard.cfm" and ThisTemplate is not "EditShedule.cfm" and (StartRow is not 1 or NrRows LT RecCount)>
			<cfoutput><font color="red"><b>Row #StartRow#-#min(RecCount,evaluate(StartRow+NrRows-1))# out of #RecCount# displayed.</b> (Max. rows displayable on screen=250, in Excel=20.000)<br></font></cfoutput>
			<cfif Printerfriendly is 0>
				<table border="0" width="100%" align="center">
					<tr><cfinclude template="PrevNext.cfm"></tr>
				</table><!--- </td></tr> --->
			</cfif>
		</cfif>
	</cfif>
	<!---     </table> --->

<cfif not isdefined("confidentialFieldsAll")>
	<!--- Region: George added @2014-4-17 for 2014ER4831 --->
	<cfinvoke component="#LMComponentPath#.admin.component.AccessControl" method="getConfidentialFields" returnvariable="confidentialFieldsAll">
	    <cfinvokeargument name="profileStruct" value="#PROF#" />
	    <cfinvokeargument name="dataType" value="Asset" />
	    <cfinvokeargument name="Labs" value="#Labs#" />
	    <cfinvokeargument name="datasource" value="#LMDB#" />
	    <cfinvokeargument name="xUID" value="#xUID#" />
	</cfinvoke>
	<cfset confidentialFields0 = Iif(structKeyExists(confidentialFieldsAll, "0"), evaluate(DE("confidentialFieldsAll.0")), "") />
</cfif>

<cfinvoke component="#LMComponentPath#.admin.component.Reservation" method="getReservationsByCurrentUser" returnvariable="reservations">
    <cfinvokeargument name="datasource" value="#LMDB#" />
    <cfinvokeargument name="xUID" value="#xUID#" />
</cfinvoke>
<cfset reservedElementIDs = valueList(reservations.ElementID) />
<!--- Region end --->

	<cfif PrinterFriendly is 0>
		<div style="width:100%;overflow-x:auto;overflow-y:hidden">
	</cfif>  
	<table border="1" id="myTable" class="table-fixed-header"> 
<thead class="header"><!--- George added @2013-1-11 for 2012R2.1#LM1205003 --->
	<!--- Region: Added by George @2012-5-24 for 2012R1.LM1201005 --->
	<cfif AT is "Allocation">
		<cfset colspanPeriodLeft = 2>
		<cfif SuperSearch is 1>
			<cfset colspanPeriodLeft = colspanPeriodLeft + 1>
		</cfif>
		<cfset totalMinutes = DateDiff("n", shedStart, DateAdd("d", 1, shedEnd))>
		<cfset totalDays = Int(totalMinutes / 1440)>
		<cfset totalHours = Int((totalMinutes - totalDays * 24 * 60) / 60)>
		<cfset totalMinutes = (totalMinutes - totalDays * 24 * 60 - totalHours * 60)>
		<cfoutput>
		<tr> 
			<td colspan="#colspanPeriodLeft#" rowspan="2">&nbsp;</td>
			<td bgcolor="silver" align="center" nowrap>Period Start</td>
			<td bgcolor="silver" align="center" nowrap>Period End</td>
			<td bgcolor="silver" align="center" colspan="3">Period Time</td>
		</tr>
		<tr>
			<td align="center" nowrap>#DateFormat(shedStart, "d-mmm-yyyy")#</td>
			<td align="center" nowrap>#DateFormat(shedEnd, "d-mmm-yyyy")#</td>
			<td align="center" colspan="3">
				<cfif totalDays gt 0>#totalDays# days</cfif>
				<cfif totalHours gt 0 or (totalDays gt 0 and totalMinutes gt 0)>#totalHours# hours</cfif>
				<cfif totalMinutes gt 0>#totalMinutes# min.</cfif>
			</td>
		</tr>
		</cfoutput>
	</cfif>
	<!--- Region end --->

	<cfif CapexData is 1 and Printerfriendly is 0>
		<cfset MainCols=32+ListLen(UsedColumns)> <!--- KV:20120907: added 1 for site i think --->
		<cfif AT is not "Element" and AT is not "Planning" and AT is not "Allocation">
			<cfset MainCols=MainCols>
		</cfif>
		<cfif ThisTemplate is "ReserveWizard.cfm" or ThisTemplate is "EditShedule.cfm" or ThisTemplate is "AcceptReservation.cfm" OR ThisTemplate IS "AcceptTransferEOwner.cfm"  or ThisTemplate is "ReserveUpload.cfm">
			<cfset MainCols=MainCols+1>
		</cfif>
		<cfif SuperSearch is 1>
			<cfset MainCols=MainCols+1>
		</cfif>
		<cfif AT is "Planning">
		<cfset MainCols=MainCols+13> <!--- Modified by Cindy @2012-06-11  original(MainCols=MainCols+11)--->
		<cfif HourlyUseForSearch is 1>
			<cfset MainCols=MainCols+2>
		</cfif>
			
		</cfif>
		<cfif AT is "Asset">
			<cfset MainCols=MainCols>
		</cfif>

		<!--- Region: Added by George @2012-5-24 for 2012R1.LM1201005 --->
		<cfif AT is "Allocation">
			<cfset MainCols = MainCols + 7> <!--- George modified @2012-11-12 for 2012R2 --->
			<cfset colspanPeriodLeft = 24>
			<cfset colspanPeriodRight = MainCols - 30>
		</cfif>
		<!--- Region end --->
		<tr bgcolor="silver">
			<td colspan="<cfoutput>#MainCols#</cfoutput>" align="center"><b>LABMAN DATA</b></td>
			<td colspan="18" bgcolor="aqua" align="center"><b>CAPEX DATA</b></td> <!--- Modified by Cindy original is 16--->
			<td bgcolor="silver" align="center">MAP</td>
		</tr>
	</cfif>   
	<tr bgcolor="silver">
	<cfif AT is not "Element" and AT is not "Planning" and AT is not "Allocation">
		<td>
		<cfif AT is "Asset">
			<cf_inc_includesortcode F_Label="#ATLabel#" F_Name="E.AssetNumber">
		<cfelseif AT is "IPAddress">
			<cf_inc_includesortcode F_Label="#ATLabel#" F_Name="E.IPAddresses">
		<cfelseif AT is "Spare">
			<cf_inc_includesortcode F_Label="#ATLabel#" F_Name="I.F8">
		</cfif>
		</td>
	</cfif>


<!-- Added by Tony -->
<cfif (AT is "Element" or AT is "Planning") and not isdefined('ExcelOutput')> <!--- KV@20170131: This Cart code is to be excluded for Excel output --->
	<script language="javascript" type="text/javascript">

		function selectAll(){
			var getElementsByClassName = function(searchClass,node,tag) {
				if(document.getElementsByClassName){
					return  document.getElementsByClassName(searchClass)
				}else{    
					node = node || document;
					tag = tag || '*';
					var returnElements = []
					var els =  (tag === "*" && node.all)? node.all : node.getElementsByTagName(tag);
					var i = els.length;
					searchClass = searchClass.replace(/\-/g, "\\-");
					var pattern = new RegExp("(^|\\s)"+searchClass+"(\\s|$)");
					while(--i >= 0){
						if (pattern.test(els[i].className) ) {
							returnElements.push(els[i]);
						}
					}
					return returnElements;
				}
			}	
			var operation = getElementsByClassName('operation');
			for(var i=0; i<operation.length; i++){
				operation[i].checked = true;
			}
		}
		function selectNone(){
			var getElementsByClassName = function(searchClass,node,tag) {
				if(document.getElementsByClassName){
					return  document.getElementsByClassName(searchClass)
				}else{    
					node = node || document;
					tag = tag || '*';
					var returnElements = []
					var els =  (tag === "*" && node.all)? node.all : node.getElementsByTagName(tag);
					var i = els.length;
					searchClass = searchClass.replace(/\-/g, "\\-");
					var pattern = new RegExp("(^|\\s)"+searchClass+"(\\s|$)");
					while(--i >= 0){
						if (pattern.test(els[i].className) ) {
							returnElements.push(els[i]);
						}
					}
					return returnElements;
				}
			}	
			var operation = getElementsByClassName('operation');
			for(var i=0; i<operation.length; i++){
				operation[i].checked = false;
			}
		}
	</script>
	<cfif HTitle is not "Reserve WIZARD">
		<td align="center" style="padding:5px"><img src="images/cart_up.png" style="width:25px; height=25px"><br><input id="myOperate" type="checkbox" onclick="if(this.checked==true)selectAll();else selectNone();"></td>
	</cfif>
</cfif>
<!-- Region end -->


	<cfif AT is "Planning">
		<cfif not isdefined("ExcelOutput") and (ThisTemplate is "AcceptReservation.cfm" or ThisTemplate is "Search.cfm" OR ThisTemplate IS "AcceptTransferEOwner.cfm")>
			<cfset AcceptRejectFunction=1>
		</cfif>
		<cfif ThisTemplate is "ReserveWizard.cfm" or ThisTemplate is "EditShedule.cfm" or ThisTemplate is "ReserveUpload.cfm">
			<td><b>Reserve</b></td>
		<cfelseif isdefined("AcceptRejectFunction")>
			<td nowrap><b>Accept<br>Reject<br>(click thumb)</b></td>
			<td><b>Change</b></td>
		</cfif>
	</cfif>
	<!--- Region: Added by George @2012-5-24 for 2012R1.LM1201005 --->
	<cfset attrForAllocation = "">
	<cfif AT is "Allocation">
		<cfset attrForAllocation=" rowspan='2'">
	</cfif>
	<!--- Region end --->
	<cfif SuperSearch is 1>
		<td<cfoutput>#attrForAllocation#</cfoutput>><b>Lab</b></td>
	</cfif>



	<td<cfoutput>#attrForAllocation#</cfoutput> nowrap><cf_inc_includesortcode F_Label="Status" F_Name="E.[Status]"></td>
	<td<cfoutput>#attrForAllocation#</cfoutput> nowrap><cf_inc_includesortcode F_Label="Type" F_Name="E.[Type]"></td>
	<td<cfoutput>#attrForAllocation#</cfoutput> nowrap><cf_inc_includesortcode F_Label="Subtype" F_Name="E.[Subtype]"></td>
	<td<cfoutput>#attrForAllocation#</cfoutput> nowrap><cf_inc_includesortcode F_Label="Name" F_Name="E.[Name]"></td>
	<cfif AT is "Planning">
		<cfif not(isdefined("WeekReport") and WeekReport is 1)>
			<!--- Region: Modified by George @2012-5-18 for 2012R1.LM1201005 --->
			<td align="center" colspan="2">
				<b>From - Till</b>
				<cfif HourlyUseForSearch is 1><br/>
				<span style="color:blue;font-weight:bold;"><cfoutput>#getUserTimeZone.TimeZone#</cfoutput></span>
				</cfif>
			</td>
			<!--- Region end --->
		</cfif>
	</cfif>
	<cfif AT is "Planning">
		<td><b>Reserve State</b></td>
		<td><b>Delivery State</b></td>
		<td><b>Reservation Remark</b></td>
		<td><b>Reserved by<br>NAME</b></td>
		<!--- Region: Added by Cindy @2012-5-24 for LM1203021 --->
		<td nowrap><b>Reserved by<br>Costcenter ID</b></td>
		<td nowrap><b>Reserved by<br>Costcenter NAME</b></td>
		<!--- Region: end --->
		<!--- Region: Added by George @2012-5-18 for 2012R1.LM1201005 --->
		<cfif isdefined("WeekReport") and WeekReport is 1>
			<td><b>WEEK</b></td>
			<td><b>Nbr.of days</b></td>
		<cfelse>
			<td><b>Nbr.of days</b></td>		
			<!--- Region: Added by George @2012-5-18 for 2012R1.LM1202024, 2012R1.LM1201005 --->
			<cfif HourlyUseForSearch is 1>
				<cfif listlen(selectedColumnList) and listfind(selectedColumnList,'Nbr.of hours')><td><b>Nbr.of hours</b></td></cfif>
				<cfif listlen(selectedColumnList) and listfind(selectedColumnList,'Nbr.of min.')><td><b>Nbr.of min.</b></td></cfif>
			</cfif>
			<!--- Region end --->
		</cfif>
		<!--- Region end --->
		<cfif isdefined("ExcelOutput")>
			<td><b>ProjectName</b></td>
			<td><b>SubProjectName</b></td>
			<td><b>ProjectDescription</b></td>
			<td><b>ProjectManager</b></td>
		<cfelse>
			<cfif listlen(selectedColumnList) and listfind(selectedColumnList,'for Project')><td><b>for Project</b></td></cfif>
		</cfif>
		<td><b>Power On Type</b></td>
	</cfif>
	
	<!--- Region: Added by George @2012-5-24 for 2012R1.LM1201005 --->
	<cfif AT is "Allocation">
		<td align="center" colspan="3"><b>Allocated Time</b></td>
		<td rowspan="2"><cf_inc_includesortcode F_Label="Alloc.<br/>(%)" F_Name="NbrOfMinutes"></td>
<!--- Region: George added @2012-10-29 for 2012R2#1149 --->
		<td rowspan="2"><cf_inc_includesortcode F_Label="Project" F_Name="ProjectName"></td>
		<td rowspan="2"><cf_inc_includesortcode F_Label="SubProject" F_Name="ProjectSubName"></td>
		<td rowspan="2"><cf_inc_includesortcode F_Label="Project Resp" F_Name="ProjectResp"></td>
<!--- Region end --->
	</cfif>
	<td<cfoutput>#attrForAllocation#</cfoutput> nowrap><cf_inc_includesortcode F_Label="Short Description" F_Name="E.[ProductName]"></td>
	<cfif AT is "Element"><td<cfoutput>#attrForAllocation#</cfoutput> nowrap><b><u>Reserve State</u></b></td></cfif>
	<!--- Region end --->   
	<cfloop list = "#selectedColumnList#" index="k"> 
	<cfif NOT listFind('Nbr.of hours,Nbr.of min.',k)>
		
		 <cfif listFind('Found on MAP(S),Last update date,First update date',k)> 
				<td<cfoutput>#attrForAllocation#</cfoutput> nowrap><b><cfoutput>#k#</cfoutput></b></td>
		 <cfelse>
		
		   <cfoutput> 
		   
			<cfif listFind(ucase(flabelList),ucase(k)) >
				 <td<cfoutput>#attrForAllocation#</cfoutput> nowrap>			 
				
						<cf_inc_includesortcode F_Label="#k#" F_Name="#listGetAt(fnameList,listFind(ucase(flabelList),ucase(k)),',')#">
				
				<cfif k EQ "Item Code">
					<cfif not isdefined("ExcelOutput")><cfinclude template="FutureFieldNamechanges.cfm"></cfif>
				</CFIF>
				<cfif k EQ "Commercial Status" >
					<cfif not isdefined("ExcelOutput")>
						<img src="images/icon_info2.gif" onmouseover="drc(this,300,150,'Commercial Status', 'This indication is automatically added from ALPIM and shows the commercial status related with the lifecycle of the product.<br>Examples:<br>- <b>IP</b>: In preparation<br>- <b>RL</b>: Released<br>- <b>MD</b>: Manufacturing discontinued<br>- <b>SD</b>: Service Discontinued');" onmouseout="HideHelp(); return true;">
					</cfif>
				</cfif>
				</td>
			</cfif>
			</cfoutput> 
			 			 
			<cfif listfind(ucase(legendlist),ucase(k)) GT 0>
				
				<Cfset j = listGetAt(legendFList,listfind(ucase(legendlist),ucase(k)),',')>  
				 
				<cfoutput query="GetElementInfoLegend">		
					 <cfif ucase(evaluate(j)) is not "">
						<td<cfoutput>#attrForAllocation#</cfoutput> nowrap>		
						
							<cfif ucase(evaluate(j)) is not "STATUS" and ucase(evaluate(j)) is not "" and j is not "UpdatedBy" and j is not "UpdateDate">
							 
					<!--- KV: previous version	<cf_inc_includesortcode F_Label="#evaluate(j)#" F_Name="I.[#j#]"> --->
									<cf_inc_includesortcode
					<!--- Region: George modified @2013-2-8 for 2013ER#LM1210004 --->
									 F_Label="#Iif(isdefined('SemiFixedFields') and StructKeyExists(SemiFixedFields, j),'SemiFixedFields[j]','evaluate(j)')#"
					<!--- Region end --->
									 F_Name="I.[#j#]">		
								 
							</cfif>
						</td>
					 </cfif>
				</cfoutput>	
				
			</cfif> 
	 </CFIF>
	</cfif>
</cfloop>

	<cfif CapexData is 1 and Printerfriendly is 0>
		<td<cfoutput>#attrForAllocation#</cfoutput>><cf_inc_includesortcode F_Label="SubNumber" F_Name="SubNumber"></td>
		<td<cfoutput>#attrForAllocation#</cfoutput>><cf_inc_includesortcode F_Label="Locationcode" F_Name="Room"></td>
		<td<cfoutput>#attrForAllocation#</cfoutput>><cf_inc_includesortcode F_Label="Plant" F_Name="Plant"></td>
		<td<cfoutput>#attrForAllocation#</cfoutput>><cf_inc_includesortcode F_Label="Class" F_Name="Class"></td>
		<td<cfoutput>#attrForAllocation#</cfoutput>><cf_inc_includesortcode F_Label="CostCenter" F_Name="CostCenter"></td>
		<td<cfoutput>#attrForAllocation#</cfoutput> nowrap><cf_inc_includesortcode F_Label="Capex Type" F_Name="CapexType"></td>
		<td<cfoutput>#attrForAllocation#</cfoutput> nowrap><cf_inc_includesortcode F_Label="Capex Name" F_Name="CapexName"></td>
		<td<cfoutput>#attrForAllocation#</cfoutput>><cf_inc_includesortcode F_Label="Supplier" F_Name="Supplier"></td>
		<!---     <td><cf_inc_includesortcode F_Label="Manufacturer" F_Name="Manufacturer"></td> --->
		<td<cfoutput>#attrForAllocation#</cfoutput>><cf_inc_includesortcode F_Label="SerialNbr." F_Name="SerialNbr"></td>
		<td<cfoutput>#attrForAllocation#</cfoutput>><cf_inc_includesortcode F_Label="CapitalisationDate" F_Name="CapitalisationDate"></td>
		<td<cfoutput>#attrForAllocation#</cfoutput>><cf_inc_includesortcode F_Label="Accumulated Depreciation" F_Name="AccumulatedOrdDepreciation"></td>
		<td<cfoutput>#attrForAllocation#</cfoutput>><cf_inc_includesortcode F_Label="Acquisition value" F_Name="AcquisitionValue"></td>
		<td<cfoutput>#attrForAllocation#</cfoutput>><cf_inc_includesortcode F_Label="Planned depreciation" F_Name="PlannedOrdDepreciation"></td>
		<td<cfoutput>#attrForAllocation#</cfoutput>><cf_inc_includesortcode F_Label="Current Bookvalue" F_Name="CurrentBookvalue"></td>
		<!---     <td><cf_inc_includesortcode F_Label="Depreciation Startdate" F_Name="OrdDepreciationStartdate"></td> --->
		<td<cfoutput>#attrForAllocation#</cfoutput>><cf_inc_includesortcode F_Label="Usefull Life (years)" F_Name="UsefullLifeInYears"></td>
			
		<!--- Region: Cindy @2012-06-08 for LM1202018  --->
		<td <cfoutput>#attrForAllocation#</cfoutput>><cf_inc_includesortcode F_Label="Deactivation Date" F_Name="Deactivation Date"></td>
		<td<cfoutput>#attrForAllocation#</cfoutput>><cf_inc_includesortcode F_Label="Inventory Note" F_Name="Inventory Note"></td>
		<!--- Region: end --->
			
		<!---     <td><cf_inc_includesortcode F_Label="Expired Usefull Life (years)" F_Name="ExpiredUsefullLifeInYears"></td>
	    <td><cf_inc_includesortcode F_Label="Book value begin fisc. year" F_Name="BookValBeginFiscYear"></td>
	    <td><cf_inc_includesortcode F_Label="Book value end fisc. year" F_Name="BookValEndFiscYear"></td> --->
				
		<!--- capex list value  ()  chen yi added 20100905  --->
		<td<cfoutput>#attrForAllocation#</cfoutput>><cf_inc_includesortcode F_Label="Currency" F_Name="Currency"></td>
	</cfif>
	
	<!--- <cfif AT is "Planning">
	    	<td><b>Request shipment to</b></td>
	    </cfif> --->
	</tr>
</thead><!--- George added @2013-1-11 for 2012R2.1#LM1205003 --->
<tbody>
	<tr>
	<cfset OldName="">
	<cfset OldLabID="">
	<cfset OldSheduleID="0">
	<cfset OldMapName="">
	<cfif AT is not "Planning">
		<cfset SheduleID="0">
	</cfif>
	<!--- Region: Added by George @2012-5-24 for 2012R1.LM1201005 --->
	<cfif AT is "Allocation">
		<tr bgcolor="silver">
			<td><b>days</b></td>
			<td><b>hours</b></td>
			<td><b>min.</b></td>
		</tr>
	</cfif>
	<!--- Region end --->

	<!--- Region: Modified by George @2012-5-16 for 2012R1.LM0611001 --->
<link rel="stylesheet" type="text/css" media="screen" href="css/ui-lightness/jquery-ui-1.8.1.custom.css" />
<script language="javascript" type="text/javascript">
	<cfif isdefined("AcceptRejectFunction") and AcceptRejectFunction is 1>
		$(document).ready(function(){
			var oEndDate = $('[id^=EndDate_]');
			if (oEndDate.length > 0){
				oEndDate.datepicker({
					dateFormat : 'yy-mm-dd',
					constrainInput:true,
					changeYear : true,
					changeMonth: true,
					showOn : 'both',
					appendText: '[YYYY-MM-DD]',
					buttonImage : 'images/cal.gif',
					buttonImageOnly : 'true'
				});
			}
			var datepicker = document.getElementById('ui-datepicker-div');
			if (datepicker){
				datepicker.style.clip = 'rect(auto, auto, auto, auto)';
			}
		});
		<!--- Region: Added by George @2012-5-14 for 2012R1.LM1202024 --->
		function changeEndDateTime(sheduleID){
			var idSelEndHour = '#ehour_' + sheduleID + ' option:selected';
			var idSelEndMinute = '#eminute_' + sheduleID + ' option:selected';
			var strTime = $(idSelEndHour).html() + ':' + $(idSelEndMinute).html();
			$('#EndDateTime_' + sheduleID).val(strTime);
		}
		function validateEndDate(sheduleID, elementName, strStartDate, strEndDate){
	    	var c = $('#EndDate_' + sheduleID);
	    	var msg = '', validData = null;
	    	var selDate = new Date(c.val().replace(/-/g,'/'));
	    	if (!(Object.prototype.toString.call(selDate) === "[object Date]") || isNaN(selDate.getTime())){
	    		msg = 'Format of End Date is invalid';
	    	}else{
		    	var minDate = new Date(strStartDate.replace(/-/g,'/'));
		    	var maxDate = new Date(strEndDate.replace(/-/g,'/'));
				if (selDate < minDate){
					validData = strStartDate;
					msg = 'Please note that reservation of Element ' + elementName + ' was ONLY accepted UNTIL the day LATER than ' + strStartDate;
				}else if (selDate > maxDate){
					validData = strEndDate;
					msg = 'Please note that reservation of Element ' + elementName + ' was ONLY accepted UNTIL the day NOT LATER than ' + strEndDate;
				}else{
					return true;
				}
	    	}
			c.focus();
			c.select();
			alert(msg);
	    	if (validData && validData != ''){
				c.val(validData);
				c.select();
	    	}
		    return false;
		}
		function validateEndDateTime(sheduleID, elementName, strStartDate, strEndDate, timeStartDate, timeEndDate){
	   		var c = $('#EndDateTime_' + sheduleID);
	   		var msg = '', validData = null;
			var strTime = '2000/1/1 ' + c.val();
			var selTime = new Date(strTime);
	    	if (!(Object.prototype.toString.call(selTime) === "[object Date]") || isNaN(selTime.getTime())){
	    		msg = 'Format of End Date Time is invalid';
	    	}else{
	    		$('#EndDate_' + sheduleID).change();
		    	var selDate = $('#EndDate_' + sheduleID).datepicker('getDate');
				strTime = $.datepicker.formatDate('yy/mm/dd', selDate) + ' ' + c.val();
				selTime = new Date(strTime);
				var minTime = new Date(strStartDate.replace(/-/g,'/') + ' ' + timeStartDate);
				var maxTime = new Date(strEndDate.replace(/-/g,'/') + ' ' + timeEndDate);
				if (selTime <= minTime){
					validData = timeStartDate;
					msg = 'Please note that reservation of Element ' + elementName + ' was ONLY accepted UNTIL the time LATER than ' + strStartDate + ' ' + timeStartDate;
				}else if (selTime > maxTime){
					validData = timeEndDate;
					msg = 'Please note that reservation of Element ' + elementName + ' was ONLY accepted UNTIL the time NOT LATER than ' + strEndDate + ' ' + timeEndDate;
				}else{
					return true;
				}
	    	}
			c.focus();
			c.select();
			alert(msg);
	    	if (validData && validData != ''){
				c.val(validData);
				c.select();
	    	}
	    	return false;
		}
		<!--- Region end --->
	</cfif>
	<!--- Regoin end --->
</script>

	<cfloop query="GetSearch">
<!--- Region: George added @2014-4-4 for 2014ER4831 --->
		<cfif listContains(reservedElementIDs, "#ID#")>
			<cfset confidentialFields = "" />
		<cfelse>
			<cfset confidentialFields = Iif(structKeyExists(confidentialFieldsAll, "#LabID#"), evaluate(DE("confidentialFieldsAll.#LabID#")), "confidentialFields0") />
		</cfif>
<!--- Region end --->
		<cfoutput>
		<cfif not isdefined("Pending")>
			<cfset Pending="">
		</cfif>
		
		<cfif OldName is not Name or OldLabID is not LabID or OldSheduleID is not SheduleID
		 or (isdefined("OldWeek") and OldWeek is not Week) <!--- Added by George @2012-5-21 for 2012R1.LM1201005 --->
		 or (AT is "Allocation")> <!--- George added @2012-11-12 for 2012R2 --->
			<cfif OldName is not ""></td></tr></cfif>
			<tr <cfif Pending is 9>bgcolor="yellow"<cfelseif Pending is 8>bgcolor="orange"</cfif>>
			

<!-- add by haopi-->
			<cfif AT is "Planning" and HTitle is not "Reserve WIZARD" and not isdefined('ExcelOutput')> <!--- KV@20170131: This code is to be excluded for Excel output --->
				<td align="center"><input class="operation" type="checkbox" name="myElementID" value="#ID#"></td>
			</cfif>
	<!-- end-->


			<cfif AT is not "Element" and AT is not "Planning" and AT is not "Allocation">
				<td nowrap>
				<cfif AT is "Asset">
					<cf_inc_writeformatlabmantext inp_buf="#AssetNumber#">
				<cfelseif AT is "IPAddress">
					<cf_inc_writeformatlabmantext inp_buf="#IPAddresses#">
				<cfelseif AT is "Spare">
					<cf_inc_writeformatlabmantext inp_buf="#Spare#">
				</cfif>
				</td>
			</cfif>
			<cfset transferPossible=0>
			<cfif ThisTemplate is "ReserveWizard.cfm" or ThisTemplate is "EditShedule.cfm" or ThisTemplate is "ReserveUpload.cfm">

				<td>
				<cfif Pending is 3>
					<cfset transferPossible=1>
				</cfif>
				<cfif Pending is 9  OR Pending is 2 or Pending is 3 or Pending is 4>
					
					<cfset SubmitPossible=1>
					<cfif Pending is 4>
						<cfquery name="getReceiver" datasource="#LMDB#">
							SELECT transferTo FROM labmanShedule where sheduleID = #SheduleID# 
						</cfquery>
						
						<CFIF getReceiver.transferTo NEQ #Val(xUID)# AND PROF["IsAdministrator"] EQ 0>
							<cfset SubmitPossible=0>
						</cfif>						
					</cfif>
					
					<input type="Checkbox" name="S#SheduleID#" checked>
					<cfset form.fieldnames = form.fieldnames & ",S#SheduleID#">
					<cfscript>StructInsert(form, "S#SheduleID#", "on");</cfscript>
					<cfif Pending is 2>
						<cfif NOT len(transferID)>
							<Cfset transferID = #SheduleID#>
						<cfelse>
							<Cfset transferID = transferID & ',' & "#SheduleID#">
						</cfif>
					</cfif> 
				<cfelse>
					&nbsp;
				</cfif>
				</td>
			<cfelseif isdefined("AcceptRejectFunction")>
				<td nowrap>
				<cfquery name="getReceiver" datasource="#LMDB#">
					SELECT transferTo FROM labmanShedule WHERE sheduleid = #SheduleID#
				</cfquery>
				<CFIF getReceiver.recordCount>
					<cfset receiverUID = getReceiver.transferTo>
				</CFIF>
				<cfif (Pending is 1 or Pending is 2 or Pending is 3)  and supersearch is 0 and (PROF["IsAdministrator"] is 1 or xUID is Owner  or FindNoCase(",#Owner#,",",#Persons_Delegate_O#,") GT 0 )>
					
					<cfset SubmitPossible=1>
					<input type="hidden" name="AccRej#SheduleID#" value="A">
					<input type="Checkbox" name="S#SheduleID#" checked onclick="if(this.checked) {document.AcceptShedule.AccRej#SheduleID#.value='A';document.I#SheduleID#.src='images/th_up.gif';document.I#SheduleID#.alt='Accept it';} else {document.I#SheduleID#.src='images/trans.gif';document.I#SheduleID#.alt='Do not accept or reject this shedule yet'}">
					<img name="I#SheduleID#" src="images/th_up.gif" width=25 height=19 border=0 alt="Accept it" onclick="if(document.AcceptShedule.S#SheduleID#.checked) if(document.AcceptShedule.AccRej#SheduleID#.value=='A') {document.AcceptShedule.AccRej#SheduleID#.value='R';this.src='images/th_dn.gif';this.alt='Reject it (=delete)';} else {document.AcceptShedule.AccRej#SheduleID#.value='A';this.src='images/th_up.gif';this.alt='Accept it';}">
					 
				<cfelseif  Pending IS 4 AND ((len(receiverUID) AND xUID IS receiverUID) OR PROF["IsAdministrator"] NEQ 0)>
					<cfset SubmitPossible=1>
					<input type="hidden" name="AccRej#SheduleID#" value="A">
					<input type="Checkbox" name="S#SheduleID#" checked onclick="if(this.checked) {document.AcceptShedule.AccRej#SheduleID#.value='A';document.I#SheduleID#.src='images/th_up.gif';document.I#SheduleID#.alt='Accept it';} else {document.I#SheduleID#.src='images/trans.gif';document.I#SheduleID#.alt='Do not accept or reject this shedule yet'}">
					<img name="I#SheduleID#" src="images/th_up.gif" width=25 height=19 border=0 alt="Accept it" onclick="if(document.AcceptShedule.S#SheduleID#.checked) if(document.AcceptShedule.AccRej#SheduleID#.value=='A') {document.AcceptShedule.AccRej#SheduleID#.value='R';this.src='images/th_dn.gif';this.alt='Reject it (=delete)';} else {document.AcceptShedule.AccRej#SheduleID#.value='A';this.src='images/th_up.gif';this.alt='Accept it';}">
				<cfelse>
					&nbsp;
				</cfif>
				</td>
				<td align="center">
				<!--- <cfif supersearch is 0 and (isdefined("IsAdministrator") or xUID is Owner or (len(receiverUID) AND xUID IS receiverUID) or FindNoCase(",#Owner#,",",#Persons_Delegate_O#,") GT 0) and PlatformGroupName is ""> --->
				
				<cfif SheduleID GT 0 and supersearch is 0 and (PROF["IsAdministrator"] is 1 or xUID is Owner or FindNoCase(",#Owner#,",",#Persons_Delegate_O#,") GT 0 or xUID is ProjectResp or FindNoCase(",#ProjectResp#,",",#Persons_Delegate_P#,") GT 0) and (PlatformgroupName is "" or PlatformGroupName is Name)>  <!--- mother element for a platform could be editable --->
					<a href="EditShedule.cfm?ChangeRequestor=1&ElementID=#ID#&SheduleID=#SheduleID#"><img src="images/USERS.GIF" width=15 height=15 alt="Change requestor" border="0"></a><a href="EditShedule.cfm?&ElementID=#ID#&SheduleID=#SheduleID#"><img src="images/EDITSM.GIF" width=25 height=15 alt="Edit reservation" border="0"></a>
				<cfelse>
					x
				</cfif>  
				</td>
			</cfif>
			<cfif SuperSearch is 1>
			<td nowrap>#LabName#</td>
			</cfif>
			<!--- KV20120808: Show all data in all rows (quickfix for shuffled columns)
			<cfif OldName is Name and OldLabID is LabID and not isdefined("ExcelOutput")>
				<cfif HourlyUseForSearch is not 1>
					<cfset csp=35>
				<cfelse>
					<cfset csp=37>
				</cfif>
				<td colspan="#csp+1#">&nbsp;</td>
			<cfelse> --->
			<cfif 1 is 1>
				<!---
				added by chen yi 20100825 
				Dynamic display status if the OOT is uploaded 	
				--->
				<cfinvoke component="#LMComponentPath#.admin.component.Utils"
					method="getCaliReportStatus" returnvariable="caliReportStatus">
					<cfinvokeargument name="datasource" value="#LMDB#"> 
					<cfinvokeargument name="labid" value="#labID#">
					<cfinvokeargument name="elementid" value="#ID#">
				</cfinvoke>
				<cfset ElementStatus=Status>
				<cfset CalibExpired=0>
				<cfif isdate(CalibrationDate)>
					<cfif CalibrationDate LT NOW()-1>
						<cfif FindNoCase("Calib",ElementStatus) is 0 and FindNoCase("Expired",ElementStatus) is 0>
							<cfset ElementStatus="#ElementStatus#&nbsp;&nbsp;Calib. EXPIRED">
						</cfif>
						<cfset CalibExpired=1>
					</cfif>
				</cfif>
				<cfif Reservable is 1 and CalibExpired is 0>
					<cfif caliReportStatus is "">
						<cfset StatusBG="##B8FE96">
					<cfelse>
						<cfset ElementStatus= ElementStatus & caliReportStatus>
						<cfset StatusBG="fuchsia">
					</cfif>
					<!--- Region: Removed by George @2012-5-11 for LM1202024 >
					<cfelseif ElementStatus is "Hourly Use">
						<cfset StatusBG="##A9FEAD">
					<--- Region end --->
				<cfelse>
					<cfset StatusBG="fuchsia">
				</cfif>

<!-- Added by Tony -->
			<cfif AT is "Element" and HTitle is not "Reserve WIZARD" and not isdefined('ExcelOutput')> <!--- KV@20170131: This code is to be excluded for Excel output --->
				<td align="center"><input class="operation" type="checkbox" name="myElementID" value="#ID#"></td>
			</cfif>
<!-- Region end -->

				<td nowrap bgcolor="#statusbg#"><cf_inc_writeformatlabmantext inp_buf="#ElementStatus#"></td>
				<!--- Region: Removed by George @2012-5-11 for LM1202024 >
				<cfif ElementStatus is "HOURLY USE">
					<cfset ReserveHours=1>
				<cfelse>
					<cfset ReserveHours=0>
				</cfif>
				<--- Region end --->
				<td nowrap>#Type#<cfif Type is "">&nbsp;</cfif></td>
				<td nowrap>#Subtype#<cfif Subtype is "">&nbsp;</cfif></td>

				<td nowrap>
				<cfset bubblePara = Name>
				<cfset bubbleParaPState = xPowerState>
				<cfset bubbleParaID = ID>
				<cfset bubbleParaLink = getSearch.ecoServerLink>
				<cfset bubbleReservable = GetSearch.reservable>
				<cfset bubbleOperational = GetSearch.operational>
				<!--- Lily added for LM1302002 @2015-6-11--->
				<cfset bubbleSheduleid = #SheduleID#>
                <!--- Region end --->
				<!--- <cfset bubbleElemPowerontype = getSearch.powerontype> --->
				<!--- Region: Added by Cindy @2012-5-15 for LM1112004-003 --->
				<cfif getSearch.Name eq getSearch.Platform>
					 <cfinvoke component="#LMComponentPath#.admin.component.Elements" method="SetElementPoweronType" returnvariable="bubbleElemPowerontype">
						<cfinvokeargument name="datasource" value="#LMDB#">
						<cfinvokeargument name="labID" value="#GetSearch.LabID#">
						<cfinvokeargument name="platform" value="#GetSearch.Platform#">
						<cfinvokeargument name="elementName" value="#GetSearch.name#">
					 </cfinvoke>
				<cfelse>
					<cfset bubbleElemPowerontype = getSearch.powerontype>
				</cfif>
				<!--- Puviarasi Subramanian Apr 8th 2019--->
				<cfset elemPoweronType = bubbleElemPowerontype>
				 
				<!--- Region end --->
			<!-- add by haopi-->
				<cfset bubble_lb_haopi=GetSearch.LabID>
			<!--haopi end -->

				<cfinclude template="bubbleInfoPower.cfm"> 
				</td>
				
				<cfif AT is "Planning">
					<cfinclude template="SearchPlanningResultCells.cfm">
					<!--- when user makes a NEW reservation of an element that is in deliverystatus=Delivered
					 they get a warning on screen that the device might be unavailable 
					 because it was not yet returned and it is not clear when this device will re-appear. --->
					<cfinvoke component="#LMComponentPath#.admin.component.Utils"
						method="getStatusInSchedule" returnvariable="PoolStatus4Element">
						<cfinvokeargument name="datasource" value="#LMDB#"> 
						<cfinvokeargument name="elementid" value="#val(ID)#">
					</cfinvoke><!---<cfdump var="#PoolStatus4Element#">--->
					<cfif PoolStatus4Element neq "">
						<cfset PoolNotReturn = PoolStatus4Element>
					</cfif>
					<cfif SheduleID is 0>
						 <cfset NoReservCSP=9> <!---- 9 Reservation columns --->
						 
						<cfif HourlyUseForSearch is 1><cfset NoReservCSP+=2></cfif> <!--- When hourly use, 2 extra columns --->
						<cfif isdefined("ExcelOutput")><cfset NoReservCSP+=3></cfif> <!--- When export to XLS: 3 extra columns for project split into name,subname,description,responsible --->
						 
						 	
							<cfif  HourlyUseForSearch>									
								<CFIF (NOT listlen(selectedColumnList) AND len(customReport)) OR (listlen(selectedColumnList) AND NOT listFind(selectedColumnList,"Nbr.of hours"))>
									<cfset NoReservCSP -= 1>
								</cfif>
								<CFIF (NOT listlen(selectedColumnList) AND len(customReport)) OR (listlen(selectedColumnList) AND NOT listFind(selectedColumnList,"Nbr.of min."))>
									<cfset NoReservCSP -= 1>							 
								</cfif>								
							</cfif> 
							<CFIF (NOT listlen(selectedColumnList) AND len(customReport)) OR (listlen(selectedColumnList) AND NOT listFind(selectedColumnList,"for Project")) AND NOT isDefined('ExcelOutput')>
									<cfset NoReservCSP -= 1>							 
							</cfif>
						<td colspan="<cfoutput>#NoReservCSP#</cfoutput>" nowrap bgcolor="silver" align="center">Not scheduled yet<cfoutput>#NoReservCSP#</cfoutput></td> <!--- Modified by Cindy @2012-06-08 and by KV:20120809: 3 extra cols for Exceloutput --->
					<cfelse>
						<td nowrap<cfif Pending is 9 or Pending is 2 OR pending is 3> bgcolor="Lime"</cfif>>
						<cfif Pending is 1>
							<font color="red">Pending</font>
						<cfelseif Pending is 0 OR Pending is 2>
							<font color="green">Reserved</font>
						<cfelseif Pending is 3>
							<font color="green">Transfer Pending</font>
						<cfelseif Pending is 4>
							<font color="green">Transferring</font>
						<cfelseif Pending is 8>
							<cfset NotFree=1>
							<font color="red"><b>NOT FREE</b></font>
						<cfelseif Pending is 9>
							<font color="blue">FREE</font>
						</cfif>
						</td>
						
						<td nowrap>
						<cfif SheduleStatus is "O">			          
							Ordered
						<cfelseif SheduleStatus is "D">
							Delivered
						<cfelseif SheduleStatus is "R">
							Returned
						<cfelse>
							&nbsp;
						</cfif>
						</td>
						<td bgcolor="navy" nowrap align="center">
						<cfif isdefined("AcceptRejectFunction") and Pending is 1 and supersearch is 0 and (PROF["IsAdministrator"] is 1 or xUID is Owner or FindNoCase(",#Owner#,",",#Persons_Delegate_O#,") GT 0)>
							<input type="text" name="Remark#SheduleID#" value="#Remark#" size="100" maxlength="500">
						
						<cfelse>
							<cfquery name="gerTransRemark" datasource="#LMDB#">
								select TRansferRemark,transferTo from LabmanShedule where sheduleID = #SheduleID#
							</cfquery>
							<cfif isDefined('gerTransRemark.TRansferRemark') AND len(gerTransRemark.TRansferRemark)>
								<font color="white">#gerTransRemark.TransferRemark#</font>
							<cfelse>
								<font color="white">#Remark#<cfif Remark is "">-</cfif></font>
							</cfif>
						</cfif>
						</td>
						<td nowrap>#RequestorName#</td>
						<!--- Region: Added by Cindy @2012-5-24 for LM1203021 --->
						<td>#CostcenterID#</td>
						<td><cfif #CostCenterName# eq ''>&nbsp;<cfelse>#CostCenterName#</cfif></td>
						<!--- Region: end --->
						<!--- Region: Added by George @2012-5-18 for 2012R1.LM1201005 --->
						<cfif isdefined("WeekReport") and WeekReport is 1>
							<td nowrap>#Week#</td>
							<td nowrap align="right">#round(NbrOfMinutesWeek/1440)#</td>
						</cfif>
						<!--- Region: end --->
						<cfif not(isdefined("WeekReport") and WeekReport is 1)>
	 						<cfif HourlyUseForSearch is not 1>
	 							<td nowrap align="right">#NbrOfDays#</td>
	 						<cfelse>
	 							<!--- Region: Added by George @2012-5-22 for 2012R1.LM1201005 --->
	 							<cfif HourlyUse is not 1>
	 								<td nowrap align="right">#NbrOfDays#</td>
	 								<td nowrap align="right">N/A</td>
	 								<td nowrap align="right">N/A</td>
	 							<cfelse>
	 								<cfset intDays = NbrOfMinutesWeek \ 1440>
	 								<cfset intHours = (NbrOfMinutesWeek - intDays * 24 * 60) \ 60>
	 								<cfset intMinutes = (NbrOfMinutesWeek - intDays * 24 * 60 - intHours * 60)>
	 								<td nowrap align="right">#intDays#</td>
	 								<cfif listlen(selectedColumnList) and listfind(selectedColumnList,'Nbr.of hours')><td nowrap align="right">#intHours#</td></cfif>
									<cfif listlen(selectedColumnList) and listfind(selectedColumnList,'Nbr.of min.')><td nowrap align="right">#intMinutes#</td></cfif>
	 							</cfif>
	 						</cfif>
						</cfif>
						<!--- Region end --->
						<cfif isdefined("ExcelOutput")>
							<td nowrap><font color="blue">#ProjectNameOnly# &nbsp;<cfif ProjectNameOnly is "">&nbsp;</cfif></font></td>
							<td nowrap><font color="blue">#SubProjectName# &nbsp;<cfif SubProjectName is "">&nbsp;</cfif></font></td>
							<td nowrap><font color="blue">#ProjectDescription# &nbsp;<cfif ProjectDescription is "">&nbsp;</cfif></font></td>
							<td nowrap><font color="blue">#ProjectRespName# &nbsp; <cfif ProjectRespName is "">&nbsp;</cfif></font></td>
						<cfelse>
							<cfif listlen(selectedColumnList) and listfind(selectedColumnList,'for Project')><td nowrap><font color="blue">#ProjectName# &nbsp;<cfif ProjectName is "">&nbsp;</cfif></font></td></cfif>
						</cfif>
						<td nowrap><font color="blue">#PowerOnTypeR#<cfif PowerOnTypeR is "">&nbsp;</cfif></font></td>
					</cfif>
				</cfif>
			
				<!--- Region: Added by George @2012-5-22 for 2012R1.LM1201005 --->
				<cfif AT is "Allocation">
					<cfif HourlyUse is not 1>
						<td nowrap align="right">#(NbrOfMinutes \ 1440)#</td>
						<td nowrap align="right">N/A</td>
						<td nowrap align="right">N/A</td>
					<cfelse>
						<cfset intDays = NbrOfMinutes \ 1440>
						<cfset intHours = (NbrOfMinutes - intDays * 24 * 60) \ 60>
						<cfset intMinutes = (NbrOfMinutes - intDays * 24 * 60 - intHours * 60)>
						<td nowrap align="right">#intDays#</td>
						<td nowrap align="right">#intHours#</td>
						<td nowrap align="right">#intMinutes#</td>
					</cfif>
					<cfset allocPercent = NbrOfMinutes * 100>
					<cfif isdefined("ExcelOutput")>
						<cfset txtAllocPercent = "=#allocPercent#/#TotalMinutes#">
					<cfelseif allocPercent lte 0>
						<cfset txtAllocPercent = "0">
					<cfelseif allocPercent lt TotalMinutes>
						<cfset txtAllocPercent = "&gt;0">
					<cfelse>
						<cfset txtAllocPercent = "#Round(allocPercent / TotalMinutes)#">
					</cfif>
					<td nowrap>#txtAllocPercent#</td>
<!--- Region: George added @2012-10-29 for 2012R2#1149 --->
					<td nowrap><cfif Len(ProjectName) lte 20 or isdefined("ExcelOutput")>#ProjectName#<cfelse><span title="#ProjectName#">#Left(ProjectName,17)#...</span></cfif></td>
					<td nowrap><cfif Len(ProjectName) lte 20 or isdefined("ExcelOutput")>#ProjectSubName#<cfelse><span title="#ProjectSubName#">#Left(ProjectSubName,17)#...</span></cfif></td>
					<td nowrap>#ProjectResp#</td>
<!--- Region end --->
				</cfif>
				<!--- Region end --->
</cfif>
<td nowrap><lm:ConfidentialField ConfidentialFields="" FieldName="ProductName">#ProductName#</lm:ConfidentialField></td>
<cfif AT is "Element"><td nowrap><lm:ConfidentialField ConfidentialFields="" FieldName="P">
					<cfif SheduleID EQ 0>
						Not Scheduled yet
					<cfelse>						
						<cfif Pending is 1>
							<font color="red">Pending</font>
						<cfelseif Pending is 0>
							<font color="green">Reserved</font>
						<cfelseif Pending is 8>
							<cfset NotFree=1>
							<font color="red"><b>NOT FREE</b></font>
						<cfelseif Pending is 9>
							<font color="blue">FREE</font>
						</cfif>
					</cfif>
						</lm:ConfidentialField></td></cfif>
<cfloop list = "#selectedColumnList#" index="k">	
<cfif NOT listFind('Nbr.of hours,Nbr.of min.',k)>
<cfif #k# EQ 'Found on MAP(S)'>
	<td nowrap>#Mapname#</td>
</cfif>

<cfif #k# EQ 'First update date'>
	<CFQUERY NAME="qryfirstUpdateDate"  datasource="#LMDB#">
		SELECT TOP 1 updateDate AS fDate FROM LabmanElementHistory WHERE ID = #ID# Order by Updatedate
	</cfquery>
	<td nowrap><cfif qryfirstUpdateDate.recordCount><cfoutput>#DateFormat(qryfirstUpdateDate.fDate,'MM-DD-YYYY')#</cfoutput></cfif></td>
</cfif>
<cfif #k# EQ 'Last update date'>
	<CFQUERY NAME="qryLastUpdateDate"  datasource="#LMDB#">
		SELECT TOP 1 updateDate as lDate FROM LabmanElementHistory WHERE ID = #ID# order by Updatedate desc
	</cfquery>
	<td nowrap><cfif qryLastUpdateDate.recordCount><cfoutput>#DateFormat(qryLastUpdateDate.ldate,'MM-DD-YYYY')#</cfoutput></cfif></td>
</cfif>
<cfif listFind(ucase(flabelList),ucase(k))>
	<cfset QFname = listGetAt(QFieldNameist,listFind(ucase(flabelList),ucase(k)),',')>
	<td nowrap>
	<cfif k eq 'Owner of element'>
		#OwnerName#
	<cfelse>
	
		<cfif listFind('Item Code,Long Description,Brand,Application',k)>
			<Cfset confidentialFields="" >
		</cfif>
		<lm:ConfidentialField ConfidentialFields = "#confidentialFields#" FieldName="#evaluate(QFname)#">
		<cfif listFind('Long Description,AssetNumber,IP Addresses',k)>
			<cf_inc_writeformatlabmantext inp_buf="#evaluate(QFname)#">
		<cfelse>
			<cfif QFname eq 'AutoPowerUp' >
				<cfif #evaluate(QFname)# eq 1>YES<cfelseif #evaluate(QFname)# eq 0>NO<cfelseif #evaluate(QFname)# eq ""></cfif>
			<Cfelse>
				#evaluate(QFname)#
			</cfif>
		</cfif>
		</lm:ConfidentialField>
	</cfif> 
	</td>
	<cfelseif listfind(ucase(legendlist),ucase(k))>
	<Cfset j = listGetAt(legendFList,listfind(ucase(legendlist),ucase(k)),',')> 
	<CFQUERY NAME="checkFieldPresent" dbtype="query">
		SELECT * FROM GetElementInfoLegend WHERE #j# <> '' and #j# is not NULL
	</cfquery>
	<cfif checkFieldPresent.recordCount gt 0>
		<td nowrap>	 
			 <cfoutput> 
						<cfif j is not "LabID" and j is not "Type" and ucase(evaluate(j)) is not "STATUS" and j is not "UpdatedBy" and j is not "UpdateDate">
							 #evaluate(j)#
						</cfif>
			</cfoutput>
			&nbsp;
		</td>
	</cfif>
	</cfif>
	
</cfif>
</cfloop>
	      	
			<cfif CapexData is 1 and Printerfriendly is 0>
			<td bgcolor="##DFFEA7" nowrap>#SubNumber#</td>
			<td bgcolor="##DFFEA7" nowrap>#Room#</td>
			<td bgcolor="##DFFEA7" nowrap>#Plant#</td>
			<td bgcolor="##DFFEA7" nowrap>#Class#</td>
			<td bgcolor="##DFFEA7" nowrap>#CostCenter#</td>
			<td bgcolor="##DFFEA7" nowrap>#CapexType#</td>
			<td bgcolor="##DFFEA7" nowrap>#CapexName#</td>
			<td bgcolor="##DFFEA7" nowrap>#Supplier#</td>
					<!--- <td bgcolor="##DFFEA7" nowrap>#Manufacturer#</td> --->
			<td bgcolor="##DFFEA7" nowrap>#SerialNbr#</td>
			<td bgcolor="##DFFEA7" nowrap>
				<cfif isdefined("ExcelOutput")>
					]DATEyyyymmdd:#DateFormat(CapitalisationDate,"yyyymmdd")#
				<cfelse>
					#DateFormat(CapitalisationDate)#
				</cfif>
			</td>
			<td bgcolor="##DFFEA7" nowrap>#AccumulatedOrdDepreciation#</td>
			<td bgcolor="##DFFEA7" nowrap>#AcquisitionValue#</td>
			<td bgcolor="##DFFEA7" nowrap>#PlannedOrdDepreciation#</td>
			<td bgcolor="##DFFEA7" nowrap>#CurrentBookvalue#</td>
			<!--- <td bgcolor="##DFFEA7" nowrap>#Dateformat(OrdDepreciationStartdate)#</td> --->
			<td bgcolor="##DFFEA7" align="center" nowrap>#UsefullLifeInYears#</td>
			<!--- <td bgcolor="##DFFEA7" align="center" nowrap>#ExpiredUsefullLifeInYears#&nbsp;</td><td bgcolor="##DFFEA7" nowrap>#BookValBeginFiscYear#</td><td bgcolor="##DFFEA7" nowrap>#BookValEndFiscYear#</td> --->
			<!--- capex list value  (Asset Element )  chen yi added 20100905  --->
			
			<!--- Region: Added by Cindy @2012-06-08 for LM1202018--->
			<td <cfif DeactivationDate is not "">bgcolor="red"<cfelse>bgcolor="##DFFEA7"</cfif> nowrap>#DeactivationDate#</td>
			<td bgcolor="##DFFEA7" nowrap>#InventoryNote#</td>
			<!--- Region end--->
			
			<td bgcolor="##DFFEA7" align="center" nowrap>#currency#</td>
			</cfif>
			<cfif 1 neq 1><td nowrap>#MapName#</cfif>
		    	
	     	<cfset OldName=Name>
	     	<cfset OldLabID=LabID>
	     	<cfset OldSheduleID=SheduleID>
	     	<cfset OldMapName=MapName>
<!--- Region: Added by George @2012-5-21 for 2012R1.LM1201005 --->
			<cfif isdefined("WeekReport") and WeekReport is 1>
		     	<cfset OldWeek=Week>
			</cfif>
<!--- Region end --->
    	<cfelseif OldMapName is MapName and CapexData is 1 and Printerfriendly is 0>
      		<cfif OldName is not "">
			</td>
		</tr>
		</cfif>
    	<tr <cfif Pending is 9>bgcolor="yellow"<cfelseif Pending is 8>bgcolor="orange"</cfif>>
			<cfset cs=10>
			<cfif AT is not "Element" and AT is not "Planning" and AT is not "Allocation">
				<cfset cs=cs+1>
			</cfif>
			<cfif ThisTemplate is "ReserveWizard.cfm" or ThisTemplate is "EditShedule.cfm" or ThisTemplate is "ReserveUpload.cfm">
				<cfset cs=cs+1>
			<cfelseif ThisTemplate is "AcceptReservation.cfm" OR  ThisTemplate is "AcceptTransferEOwner.cfm">
				<cfset cs=cs+1>
			</cfif>
      	<cfif SuperSearch is 1>
				<cfset cs=cs+1>
      	</cfif>
		
      	<cfif OldName is Name and OldLabID is LabID and not isdefined("ExcelOutput")>
     			<cfset cs=cs+21> <!--- KV:20120907: changed from 14 to 21 for proper capex lineup --->
        		<cfif AT is not "Asset">
           			<cfset cs=cs+1>
        		</cfif>  
      	<cfelse> 
        		<cfset cs=cs+2>
        		<cfif AT is not "Asset"> <!--- If Asset, assetnumber is already displayed as searchfield --->
        			<cfset cs=cs+1>
        		</cfif>
      	</cfif>
      	<cfif AT is "Planning">
<!---         <cfset cs=cs+5> --->
				<cfset cs=cs+11>
      	</cfif>
<!--- Region: Added by George @2012-5-24 for 2012R1.LM1201005 --->
		<cfif AT is "Allocation">
			<cfset cs = cs + 5>
		</cfif>
<!--- Region end --->
      	<cfloop INDEX="j" LIST="#UsedColumns#">
			
        		<cfif j is not "LabID" and j is not "Type" and ucase(evaluate(j)) is not "STATUS">
         		<cfset cs=cs+1>
        		</cfif>
      	</cfloop>
      		<td colspan="#cs#" align="left">
        <cfif AT is "Asset">
         	<cf_inc_writeformatlabmantext inp_buf="#AssetNumber#">
        <cfelseif AT is "IPAddress">
         	<cf_inc_writeformatlabmantext inp_buf="#IPAddresses#">
        <cfelseif AT is "Spare">
         	<cf_inc_writeformatlabmantext inp_buf="#Spare#">
        </cfif>
			</td>
			<td bgcolor="##DFFEA7" nowrap>#SubNumber#</td>
			<td bgcolor="##DFFEA7" nowrap>#Room#</td>
			<td bgcolor="##DFFEA7" nowrap>#Plant#</td>
			<td bgcolor="##DFFEA7" nowrap>#Class#</td>
			<td bgcolor="##DFFEA7" nowrap>#CostCenter#</td>
			<td bgcolor="##DFFEA7" nowrap>#CapexType#</td>
			<td bgcolor="##DFFEA7">#CapexName#</td>
			<td bgcolor="##DFFEA7">#Supplier#</td>
			<td bgcolor="##DFFEA7" nowrap>#SerialNbr#</td>
			<td bgcolor="##DFFEA7" nowrap><cfif isdefined("ExcelOutput")>]DATEyyyymmdd:#DateFormat(CapitalisationDate,"yyyymmdd")#<cfelse>#DateFormat(CapitalisationDate)#</cfif></td>
			<td bgcolor="##DFFEA7" nowrap>#AccumulatedOrdDepreciation#</td>
			<td bgcolor="##DFFEA7" nowrap>#AcquisitionValue#</td>
			<td bgcolor="##DFFEA7" nowrap>#PlannedOrdDepreciation#</td>
			<td bgcolor="##DFFEA7" nowrap>#CurrentBookvalue#</td>
			<td bgcolor="##DFFEA7" align="center" nowrap>#UsefullLifeInYears#&nbsp;</td>
			<td <cfif DeactivationDate is not "">bgcolor="red"<cfelse>bgcolor="##DFFEA7"</cfif> nowrap>#DeactivationDate#&nbsp;</td>
			<td bgcolor="##DFFEA7" nowrap>#InventoryNote#&nbsp;</td>
			<td bgcolor="##DFFEA7" align="center" nowrap>#currency#</td>
			<td nowrap>#MapName#
			
			<cfset OldName=Name>
			<cfset OldLabID=LabID>
			<cfset OldSheduleID=SheduleID>
			<cfset OldMapName=MapName>
		<cfelse>
			<br>#MapName#
		</cfif>
		</cfoutput>
	</cfloop>
	<cfif OldName is not "">
			</td>
		</tr>
	</cfif>
	</table>
	<br>
	<cfif PrinterFriendly is 0>
		</div>
	</cfif>
	<cfif not isdefined('ExcelOutput') and ThisTemplate is not "ReserveWizard.cfm" and ThisTemplate is not "ReserveUpload.cfm" and ThisTemplate is not "EditShedule.cfm" and PrinterFriendly is 0 and (StartRow is not 1 or NrRows LT RecCount)>
	


	<table border="0">
		<tr>
			<td>
		<cfoutput><font color="red"><b>Row #StartRow#-#min(RecCount,evaluate(StartRow+NrRows-1))# out of #RecCount# displayed.</b> (Max. rows displayable on screen=250, in Excel=10.000)</font></cfoutput>
			</td>
		</tr>
		<tr>
			<td>
				<table border="0" width="100%" align="center">
					<tr><cfinclude template="PrevNext.cfm"></tr>
				</table>
			</td>
		</tr>
	</table>
	</cfif>
	
	<cfif Printerfriendly is 1 and CapexData is 1 and ThisTemplate is not "ReserveWizard.cfm" and ThisTemplate is not "ReserveUpload.cfm" and ThisTemplate is not "EditShedule.cfm" and ThisTemplate is not "AcceptReservation.cfm" and ThisTemplate is not "AcceptTransferEOwner.cfm">
	<h3>CAPEX DATA:</h3>
    <table border="1">
       	<tr bgcolor="silver">
       	<cfif SuperSearch is 1>
			<td><b>Lab</b></td>
		</cfif>
      		<td><b>Name</b></td>
			<td><b>Description</b></td>
			<td><b>Assetnumber</b></td>
      		<td><b>SubNumber</b></td><td><b>Locationcode</b></td>
			<td><b>Plant</b></td>
			<td><b>Class</b></td>
			<td><b>CostCenter</b></td>
			<td nowrap><b>Capex Type</b></td>
			<td><b>Capex Name</b></td>
      		<td><b>Supplier</b></td>
      			<!--- <td><b>Manufacturer</b></td> --->
      		<td><b>SerialNbr.</b></td>
			<td><b>CapitalisationDate</b></td>
			<td><b>Accumulated Depreciation</b></td>
			<td><b>Acquisition value</b></td>
			<td><b>Planned depreciation</b></td>
			<td><b>Current Bookvalue</b></td>
      			<!--- <td><b>Depreciation Startdate</b></td> --->
      		<td><b>Usefull Life (years)</b></td>
      			<!--- <td><b>Expired Usefull Life (years)</b></td><td><b>Book value begin fisc. year</b></td><td><b>Book value end fisc. year</b></td> --->
			<!--- capex list value  ()  chen yi added 20100905  --->
      		<td><b>Currency</b></td>
      	</tr>
		<cfset OldName="">
       	<cfset OldLabID="">
       	<cfset OldSheduleID="0">
       	<cfif AT is not "Planning">
			<cfset SheduleID="0">
		</cfif>
       	<cfloop query="GetSearch">
       		<cfoutput>
       		<cfif not isdefined("Pending")>
				<cfset Pending="">
			</cfif>
       		<cfif OldName is not Name or OldLabID is not LabID or OldSheduleID is not SheduleID>
        <tr <cfif Pending is 9>bgcolor="yellow"<cfelseif Pending is 8>bgcolor="orange"</cfif>>
         		<cfif SuperSearch is 1>
			<td nowrap>#LabName#</td>
				</cfif>
         		<cfif OldName is Name and OldLabID is LabID and not isdefined("ExcelOutput")>
         	<td colspan="3">&nbsp;</td>
         		<cfelse> 
    		<td nowrap><a href="<cfif isdefined('ExcelOutput')>https://#cgi.Server_Name##LMWebPath#<cfelse>ShowElement.cfm</cfif>?ElementID=#ID#<cfif isdefined("QLU")>&QLU=#QLU#</cfif>"><u>#Name#</u></a></td>
    		<td nowrap><cf_inc_writeformatlabmantext inp_buf="#Description#"></td>
    		<td nowrap><cf_inc_writeformatlabmantext inp_buf="#AssetNumber#"></td>
         		</cfif>
         	<td bgcolor="##DFFEA7" nowrap>#SubNumber#</td><td bgcolor="##DFFEA7" nowrap>#Room#</td><td bgcolor="##DFFEA7" nowrap>#Plant#</td><td bgcolor="##DFFEA7" nowrap>#Class#</td><td bgcolor="##DFFEA7" nowrap>#CostCenter#</td><td bgcolor="##DFFEA7" nowrap>#CapexType#</td><td bgcolor="##DFFEA7" nowrap>#CapexName#</td>
         	<td bgcolor="##DFFEA7" nowrap>#Supplier#</td>
         			<!--- <td bgcolor="##DFFEA7" nowrap>#Manufacturer#</td> --->
         	<td bgcolor="##DFFEA7" nowrap>#SerialNbr#</td><td bgcolor="##DFFEA7" nowrap><cfif isdefined("ExcelOutput")>]DATEyyyymmdd:#DateFormat(CapitalisationDate,"yyyymmdd")#<cfelse>#DateFormat(CapitalisationDate)#</cfif></td><td bgcolor="##DFFEA7" nowrap>#AccumulatedOrdDepreciation#</td><td bgcolor="##DFFEA7" nowrap>#AcquisitionValue#</td><td bgcolor="##DFFEA7" nowrap>#PlannedOrdDepreciation#</td><td bgcolor="##DFFEA7" nowrap>#CurrentBookvalue#</td>
         			<!--- <td bgcolor="##DFFEA7" nowrap>#Dateformat(OrdDepreciationStartdate)#</td> --->
         	<td bgcolor="##DFFEA7" align="center" nowrap>#UsefullLifeInYears#</td>
         			<!--- <td bgcolor="##DFFEA7" align="center" nowrap>#ExpiredUsefullLifeInYears#</td><td bgcolor="##DFFEA7" nowrap>#BookValBeginFiscYear#</td><td bgcolor="##DFFEA7" nowrap>#BookValEndFiscYear#</td> --->
					<!--- capex list value  (Asset Element)  chen yi added 20100905  --->
			<td bgcolor="##DFFEA7" align="center">#currency#</td>
		
         </tr>
         		<cfset OldName=Name>
         		<cfset OldLabID=LabID>
         		<cfset OldSheduleID=SheduleID>
       		</cfif>
       		</cfoutput>
       	</cfloop>
	</table>
	</cfif><!--- end of <cfif Printerfriendly is 1 and CapexData is 1 and ThisTemplate is not "ReserveWizard.cfm" and ThisTemplate is not "ReserveUpload.cfm" and ThisTemplate is not "EditShedule.cfm" and ThisTemplate is not "AcceptReservation.cfm"> --->
	<cfif ThisTemplate is "ReserveWizard.cfm" or ThisTemplate is "EditShedule.cfm" or ThisTemplate is "ReserveUpload.cfm">
		<cfif ArrayLen(OverlapArray) GT 0>
			<cfloop index="i" from="1" to="#ArrayLen(OverlapArray)#">
				<cfoutput><input type="hidden" name="Overlap#i#" value="#OverlapArray[i]#"></cfoutput>
			</cfloop>
		</cfif>
		<cfif isdefined("Form.Project")>
			<cfset MyProject=Form.Project>
		<cfelse>
			<cfset MyProject=0>
		</cfif>
		<cfoutput><input type="hidden" name="Project" value="#MyProject#">
				  <cfset form.PROJECT  = "#MyProject#" ></cfoutput>
		<cfif isdefined("Form.Remark")>
			<cfset MyRemark=Form.Remark>
		<cfelse>
			<cfset MyRemark="">
		</cfif>
		<cfoutput><input name="Remark" type="hidden" value="#MyRemark#">
				  <cfset form.Remark  = "#MyRemark#" ></cfoutput>
		<cfquery name="ProjName" datasource="#LMDB#">
		 	Select Distinct ID as Value,Name+' ('+Description+')' as Descr from LabmanProject where ID=#MyProject# <!--- and LabID=#Lab# --->
		</cfquery> 
		<cfif ThisTemplate is not "ReserveUpload.cfm">
			<cfif ProjName.Recordcount is 1>
				<cfset MyProject=ProjName.Descr>
			<cfelse>
				<cfset MyProject="[Not project related]">
			</cfif>
			<cfoutput>
			<br>Project: <b>#MyProject#</b>
			<br>Remark: <b>#MyRemark#</b>
			</cfoutput>
		</cfif>
		
		<cfif isdefined("SubmitPossible")>
			<cfif isdefined("PoolNotReturn")>
				<br>
					<font color="red">
						<b>the element might be unavailable because it was not yet returned. The delivery status on a previous reservation indicates "delivered".</b>
					</font>
			</cfif>	
			<cfoutput>
				<input type="hidden" name="transferIds" value="#transferID#">
				<input  type="hidden" name="transferTo" value="#transferTo#">
				<input type="hidden" name="receiverID" value="#receiverID#">
				
			</cfoutput>
			<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<input class="button" type="submit" name="Reserve" value="Submit">
			
			<!--- add parameter to invoke "finish upload" --->
			<cfif isdefined("uploadtype") and uploadtype eq "online">
				<cfoutput>
				<input type="hidden" name="uploadtype" value="online">
				<input type="hidden" name="G_UploadID" value="#G_UploadID#">
				</cfoutput>
				<cfinvoke component="#LMComponentPath#.admin.component.Utils"
						method="LockUploadElement" returnvariable="isLockOK">
					<cfinvokeargument name="datasource" value="#LMDB#">	
					<cfinvokeargument name="labid" value="#lab#">	
					<cfinvokeargument name="uploader" value="#xUID#">
					<cfinvokeargument name="uploadid" value="#G_UploadID#">		
					<cfinvokeargument name="lockflg" value="0">			
					<cfinvokeargument name="finishedStep" value="3"> 
				</cfinvoke>
			</cfif>
		<cfelse>
			<cfif isdefined("uploadtype") and uploadtype eq "online">
				<cfinvoke component="#LMComponentPath#.admin.component.Utils"
						method="LockUploadElement" returnvariable="isLockOK">
					<cfinvokeargument name="datasource" value="#LMDB#">	
					<cfinvokeargument name="labid" value="#lab#">	
					<cfinvokeargument name="uploader" value="#xUID#">
					<cfinvokeargument name="uploadid" value="#G_UploadID#">		
					<cfinvokeargument name="lockflg" value="0">			
					<cfinvokeargument name="finishedStep" value="6"> 
				</cfinvoke>
			</cfif>	
			<cfset ResType="">
			<cfif isdefined("Form.Reserve")>
				<cfset ResType="R">
				<cfif Form.Reserve is "Reserve Project">
					<cfif val(Form.SYear) is 0 or val(Form.SMonth) is 0 or val(Form.SDay) is 0 or Val(Form.EYear) is 0 or val(Form.EMonth) is 0 or val(Form.EDay) is 0>
						<cfset ResType="E">  <!--- Extention of reservations requested --->
					</cfif>
				</cfif>
			</cfif>
			<cfif ResType is not "">
				<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="red"><b>No reservation<cfif ResType is "E"> changes can be done since nothing is reserved yet or cannot be changed.<br>
				Fill in both dates to make new project reservations.<cfelse>s can be made</cfif></b></font><br>
			</cfif>
			<cfif isdefined("NotFree")>
				&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="blue"><b><br>NOT FREE: You could ask 'Reserved by'-person or 'Owner' (or 'Project responsible' or Administrator) to transfer reservation to you if needed...</b></font><br>
			</cfif>
		</cfif>
		<cfif PrevPage is not "">
			<cfoutput>&nbsp;<input class="button" type="Button" name="Back" value="<cfif isdefined("SubmitPossible")>Cancel<cfelse>Back</cfif>" onclick="document.location.href='#PrevPage#';"></cfoutput>
		</cfif>
		<br><br>
		</form>
	<cfelseif AT is "Planning" and not isdefined('ExcelOutput')>
		<cfif Supersearch is 1>
			<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="blue"><b>In Multiple labs search, Accepting/Rejecting of pending reservations cannot be done.</b></font>
		<cfelseif isdefined("SubmitPossible")>
			<cfif isdefined("PoolNotReturn")>
				<br>
					<font color="red">
						<b>the element might be unavailable because it was not yet returned. The delivery status on a previous reservation indicates "delivered".</b>
					</font>
			</cfif>
			<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
			<input class="button" type="submit" name="Accept" value="Submit" id="submitAccept">
			<input  type="hidden" name="transAccept" id="transAccept" value="<cfif ThisTemplate is 'AcceptTransferEOwner.cfm'>transAccept<cfelse></cfif>">
<!---          <input type="button" name="Accept" value="Accept/Reject selected reservations" onclick="document.AcceptShedule.submit()"> --->
			&nbsp;&nbsp;&nbsp;<font color="red"><b>READ SMALL EXPLANATION BELOW ONCE if you need to ACCEPT/REJECT!</b></font><br>
			<table border="1" bordercolorlight="Aqua" cellpadding="5">
				<tr>
					<td><font color="blue">
					<b>SMALL EXPLANATION:</b><br>
					<b>Accept</b>: <u>Select checkbox</u> in Accept col. + <u>thumb up</u> means ACCEPT (=default state).<br>
					<b>Reject</b>: <u>Select checkbox</u> in Accept col. + <u>thumb down</u> means REJECT (click hand to toggle up/down)<br>
					<b>NO CHANGE</b>: <u>uncheck checkbox</u> (nothing happens, it will remain pending)<br></font>
					</td>
				</tr>
			</table>
		<cfelseif not isdefined("Form.Accept")>
			<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<font color="blue"><b>There are no pending reservations that can be accepted/rejected by you at the moment.<br></b></font><br>
		</cfif>
		<cfif PrevPage is not "">
			<cfoutput>&nbsp;<input class="button" type="Button" name="Back" value="Cancel" onclick="document.location.href='#PrevPage#';"></cfoutput>
		</cfif>
		<br><br>
		</form>
		<a href="index.cfm" target="_top">
			<img src="images/homeblue.gif" alt="Goto Labman Homepage" border="0"> HOME
		</a>
	</cfif>
	<!--- <cfif PrinterFriendly is 0>
		</div>
	</cfif> --->
</cfif>
<script language="javascript" type="text/javascript">
<!--- Region: Modified by George @2012-4-18 for 2012R1.LM0611001 --->
	var validators_EndDate = new Array();
	function validateAccept(){
		var i = 0, valid = true;
		while (valid && i < validators_EndDate.length){
			valid = validators_EndDate[i++]();
		}
		return valid;
	}
<!--- Regoin end --->
<!--- Region: George added @2013-1-11 for 2012R2.1#LM1205003 --->
	$(function(){
		var contentsObj=document.getElementById('contents')
		  , $contents=$(contentsObj)
		$('#searchPanel').toggleHandler(contentsObj);
		$('#myTable').fixedHeader({
		  container:$contents
		 ,topOffset:$contents.offset().top
		});
	});
<!--- Regoin end --->
</script>


