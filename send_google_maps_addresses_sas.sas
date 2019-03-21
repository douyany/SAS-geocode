***Date: March 20, 2019;

***This program takes a dataset with origin addresses;
***and sends them through the Google Maps API to get the driving distance (in miles);
***and driving time (in seconds);
***for 3 destination addresses;


***The address dataset that gets sent to proc geocode may need modification to fit the proc requirements and personal need;
***e.g., in the example file, all addresses are in Pennsylvania,;
***the state abbreviation (stabbr) is set to PA;


***The program is flexible to having fewer or more destination addresses;


***to modify for a different number of destination addresses:;

***a);
***change the 3 in;
***%do whichdest=1 %to 3;
***to your preferred number;

***b);
***add a %let destlat(number)=(latitude);
***for each destination up through your preferred number;

***c);
***add a %let destlong(number)=(longitude);
***for each destination up through your preferred number;

***d);
***in the merge,;
***you will want to add each file name individually;
***e.g., procedir.distance_time(number);
***for each destination up through your preferred number;

***e);
***in the merge,;
***you will want to add rename individually;
***e.g., (rename=(distance=distance_(nickname) time=time_(nickname));
***for each destination up through your preferred number;

***f);
***in the merge,;
***you will want to add each variable label individually;
***e.g., label distance_(nickname)="Distance to (nickname) in Miles";
***e.g., label time_(nickname)="Time to (nickname) in Seconds";
***for each destination up through your preferred number;





***
***
***housekeeping before the program starts;
***
***
***

***if the log is not actively modified,;
***the running of this program will generate a lot of text in the log window;
***depending on the volume of origin addresses,;
***the log window may get so full that it will pause the running of the program;

***this options of turning off a lot of the text will help decrease some of the volume of text in the log window;


***from http://support.sas.com/kb/5/888.html;
***suggestions on what to do if log window is full;
***turn off content to log;
***or else program will need to pause to clear log;

***will only want to have this part activated after am sure that program is running correctly;
options nonotes nosource nosource2 errors=0;

***added mlogic to eyeball the macros;
***make sure the macros are running correctly;
options mlogic;


***set libraries;
***location of address lookup info;
libname procedir (address location goes here);



***
***
***housekeeping ends;
***
***
***


***
***
***set the destination addresses before the program starts;
***
***
***

/*
three address locations:

Rose Bowl Stadium:
1001 Rose Bowl Dr, Pasadena, CA 91103

Met Life Stadium: 
1 MetLife Stadium Dr, East Rutherford, NJ 07073

Soldier Field:
1410 Museum Campus Dr, Chicago, IL 60605


These lat-longs will be
Rose Bowl Stadium
Met Life Stadium
Soldier Field
(in this order)

34.161327,  -118.167648
40.813778, -74.074310
41.8625332, -87.6167182
 


*/

***set the lets for the three addresses;
%let destlat1=34.161327 ;
%let destlat2=40.813778 ;
%let destlat3=41.8625332;
%let destlong1=-118.167648;
%let destlong2=-74.074310; 
%let destlong3=-87.6167182;


***
***
***set the destination addresses ends;
***
***
***




***
***
***prepare the master dataset before sending to proc geocode;
***
***
***


***if the file does not currently have row numbers in it,;
***having row numbers will make it easier when merging the distance and time information;
***back with the master dataset;

***if the file has existing ID numbers and the numbers are too large;
***for sending through proc geocode,;
***rownum can be an identifier that is small enough;
***for sending through proc geocode,;

***add row numbers to merge later;
data procedir.address_list200;
set procedir.address_list100;

***convert the ID number into a smaller number;
***it needs to be small enough to be able to send in the proc geocode procedure;

***create a rownum variable;
rownum=_n_;
label rownum="Row Number in the dataset address_list100";
run;
***4336 rows, same as distance_time files;







***add state abbreviations;
***split zip+4 into zip and into +4;
***create shorter versions of the variables that are currently too long;
data procedir.address_list300 (drop=personid familyid bxnumandst bxpostalzip streetaddr);
	set procedir.address_list200;
	
***generate variable for state abbreviation;
length stabbr $2.;
***everyone in this dataset is from Pennsylvania;
stabbr="PA";

***zip 5 is a number variable;
zip5=input(substr(bxpostalzip, 1, 5), 5.);

***zip last4 is a string variable;
length ziplast4 $4;
ziplast4=substr(bxpostalzip, 6, 4);

***convert the address string into a shorter string;
***the longest length of the entry is 35 characters;
length addrstring $42;
addrstring=substr(streetaddr, 1, 35);

run;





***
***
***send the prepared dataset through proc geocode;
***
***
***


	
***template of geocode;
*proc geocode                           /* Invoke geocoding procedure       */
*   method=STREET                       /* Specify geocoding method         */
*   data=WORK.CUSTOMERS                 /* Input data set of addresses      */
*   out=WORK.GEOCODED                   /* Output data set with X/Y values  */
*   lookupstreet=SASHELP.GEOEXM         /* Primary street lookup data set   */
*   attributevar=(TRACTCE00);           /* Assign Census Tract to locations */
*run;


***this invocation of proc geocode;

proc geocode                           /* Invoke geocoding procedure       */
   method=STREET                       /* Specify geocoding method         */
   data=procedir.address_list300                 /* Input data set of addresses      */
   out=procedir.address_list400                   /* Output data set with X/Y values  */
   lookupstreet=lookup.usm         /* Primary street lookup data set   */
   addressvar=addrstring				/* the var having the street address like 123 Main St. */
   addresscityvar=bxcity				/* the var having the city info */
   addressstatevar=stabbr				/* the var having the state abbreviation */
   addresszipvar=zip5					/* the var having the five-digit zip code */
   addressplus4var=ziplast4				/* the var having the plus4 of zip code */
   ;          
run;



****;
****;
****;
****;
****now have dataset with latlong information included;
****;
****;
****;
****;


			

****;
****;
****;
****;
****want to go through table row by row;
****;
****send the latlong of interest to Google Maps;
****;
****;
			

			
			
***information from here on how to plug info into table;
***https://communities.sas.com/t5/SAS-Communities-Library/Driving-Distances-and-Drive-Times-using-SAS-and-Google-Maps/ta-p/475839;


***get a count for the number of records in the table;
		data _null_;
			call symputx('nlls', obs);
			stop;
			set procedir.address_list400 nobs=obs;
			run;


			
* create a macro that contains a loop to access Google Maps multiple time;
%macro distance_time;


***run through the three destination stadium addresses;
%do whichdest=1 %to 3;

***set the printto to be able to track results along the way;
***will create a separate log for each stadium;
proc printto print="(pick destination directory)\log_dest&whichdest._txt.txt";

run;


* delete any data set named DISTANCE_TIME&whichdest that might exist in the WORK library;
proc datasets lib=procedir nolist;
delete distance_time&whichdest;
quit;


***create the empty dataset;
***the stop means that there will not be any observations;
data procedir.distance_time&whichdest;
stop;
distance=.;
time=.;
reflat=.;
reflong=.;
rownum=.;
label distance="Distance in Miles";
label time="Time in Seconds";
label reflat="Origin Latitude (not the stadium)";
label reflong="Origin Longitude (not the stadium)";
label rownum="Row Number from address_list100 table";

run;


***start at the first row and go to the end of the table;
%do j=1 %to &nlls;
data _null_;
nrec = &j;
set procedir.address_list400 point=nrec;
call symputx('reflat',y);
call symputx('reflong',x);
call symputx('thisrownum', rownum);
stop;
run;


***the put can monitor the status of the program;
***put down the name of the current combination being checked;
%put the rownum is &thisrownum headed to destination stadium &whichdest;


***destination url for Google Maps;
		filename x url "https://www.google.com/maps/dir/&REFLAT.,&REFLONG./&&destLAT&whichdest.,&&destLONG&whichdest./?force=lite"; 
***destination for z filename is temp;		
		filename z temp;

		
* same technique used in the example with a pair of lat/long coodinates;
data _null_; 
infile x recfm=f lrecl=1 end=eof; 
file z recfm=f lrecl=1;
input @1 x $char1.; 
put @1 x $char1.;
if eof;
call symputx('filesize',_n_);
run;

			
* drive time as a numeric variable;
***drive time will be in seconds;
data temp;
infile z recfm=f lrecl=&filesize. eof=done;
input @ 'miles' +(-15) @ '"' distance :comma12. text $30.;
units    = scan(text,1,'"');
text     = scan(text,3,'"');
* convert times to seconds;
  select;
* combine days and hours;
   when (find(text,'d') ne 0) time = sum(86400*input(scan(text,1,' '),best.), 
                                        3600*input(scan(text,3,' '),best.));
* combine hours and minutes;
   when (find(text,'h') ne 0) time = sum(3600*input(scan(text,1,' '),best.), 
                                        60*input(scan(text,3,' '),best.));
* just minutes;
   otherwise                  time = 60*input(scan(text,1,' '),best.);
  end;
output; 
keep  distance time;
stop;
done:
output;
run;
 
filename x clear;
filename z clear;
 
* add an observation to the data set DISTANCE_TIME&whichdest;
***will get a warning that reflat reflong and whichrow do not appear on the temp file;
***this warning is true;
proc append base=procedir.distance_time&whichdest data=temp;
run;

***data set with additional vars;
***replace the missing values with the current value;
***only the newly added last row will have the row as missing value;
data procedir.distance_time&whichdest;
set procedir.distance_time&whichdest;
if reflat=. then reflat=&reflat;
if reflong=. then reflong=&reflong;
if rownum=. then rownum=&thisrownum;
run;

***show the newly added row;
***this info goes into the stadium-specific log;
title "Info for newly added row &thisrownum";
proc print data=procedir.distance_time&whichdest;
where rownum=&thisrownum;
run;



		***close the loop for the set of addresses;
		%end;

	***close the loop for the destination stadium;
	%end;

		
%mend;
 
* call the macro;
%distance_time;


***after the tables are done running, run the QA check;
***how many rows have info for lat and long;	
***it should be the same number as the number of rows in the table;		



****;
****;
****;
****;
****merge together;
****master file;
****and files with info from Google Maps;
****;
****;
			

			

***merge files;
***add distance_time files;
***only need to keep one set of the reference latitudes and longitudes;
data procedir.address_list500;
merge procedir.address_list200
      procedir.distance_time1 (rename=(distance=distance_Rose time=time_Rose);
      procedir.distance_time2 (rename=(distance=distance_MetLife time=time_MetLife) drop=reflat reflong);
      procedir.distance_time3 (rename=(distance=distance_Soldier time=time_Soldier) drop=reflat reflong);
by rownum;
label distance_Rose="Distance to Rose Bowl in Miles";
label time_Rose="Time to Rose Bowl in Seconds";
label distance_MetLife="Distance to MetLife Stadium in Miles";
label time_MetLife="Time to MetLife Stadium in Seconds";
label distance_Soldier="Distance to Soldier Field in Miles";
label time_Soldier="Time to Soldier Field in Seconds";
run;
