

###################################################
# Grab and check arguments and assign to arg variable
args <- commandArgs(trailingOnly = TRUE)

# Check to see if there aren't arguments. 
if (length(args)==0 || length(args)>3 || length(args)==2) {
  stop("No arguments provided; this script requires the first or all 3 arguments: 1) path to confound regressors tsv file (REQUIRED), 2) output directory (default=pwd), 3) censor threshold (default=1mm).", call.=FALSE)
} 

# If only 1 argument, assign as the target confound file, and set output and censor to threshold. 
if (length(args)==1) {
  File = args[1]
  OutDir=getwd()
  CenThresh=1
  print(c("Will extract regressors from:",File,"and will use pwd for output, and 1mm as censor threshold"))
}

# Check if there are all three arguments
if (length(args)==3) {
  File = args[1]
  OutDir=args[2]
  CenThresh=args[3]
  print(c("Will extract regressors from:",File,"and will use:", OutDir, "for output, and", CenThresh, "as censor threshold"))
}

###################################################
## Get subject ID and Task/Run for writing to files
FileName=basename(File)
FirstUnderscore=regexpr('_',FileName)
SubID=substr(FileName,1,FirstUnderscore[1]-1)
TaskStart=regexpr('task',FileName)
DescStart=regexpr('_desc-confounds',FileName)
TaskRun=substr(FileName,TaskStart[1]+5,DescStart[1]-1)

FilePrefix=paste(SubID,'-',TaskRun,'-',sep="")

###################################################
# Read in data and start extracting relevant variables
Data = read.table(file = File, sep = '\t', header = TRUE)

# extract 6 raw motion regressors
MoPar = Data[c("rot_x","rot_y","rot_z","trans_x","trans_y","trans_z")]
# write Mopar file
write.table(MoPar,paste(OutDir,"/",FilePrefix,"MoPar.1D", sep=""), quote = FALSE, sep = "\t", row.names = FALSE, col.names = FALSE)

# create demeaned motion regressors
MoParDeMean=MoPar
for(x in 1:6){MoParDeMean[,x]=MoPar[,x]-mean(MoPar[,x])}
# write demean file
write.table(MoParDeMean,paste(OutDir,"/",FilePrefix,"MoParDeMean.1D", sep=""), quote = FALSE, sep = "\t", row.names = FALSE, col.names = FALSE)

# extract derivative motion regressors
MoParDerv = Data[c("rot_x_derivative1","rot_y_derivative1","rot_z_derivative1","trans_x_derivative1","trans_y_derivative1","trans_z_derivative1")]
MoParDerv=as.data.frame.array(MoParDerv)
for(x in 1:6){MoParDerv[1,x]<-0}

# write derivative file
write.table(MoParDerv,paste(OutDir,"/",FilePrefix,"MoParDerv.1D", sep=""), quote = FALSE, sep = "\t", row.names = FALSE, col.names = FALSE)


# extract censor regressor
FD=Data[c("framewise_displacement")]
Censor=as.data.frame.array(FD)
# replace na in first row
if(Censor[1,1]=="n/a"){
  Censor[1,1]<-0
}
write.table(Censor,paste(OutDir,"/",FilePrefix,"FD.1D", sep=""), quote = FALSE, sep = "\t", row.names = FALSE, col.names = FALSE)

# Get relevant FD data for motion summaries: 
MeanFD=mean(as.numeric(Censor[2:length(Censor[,1]),1]))
MaxFD=max(as.numeric(Censor[2:length(Censor[,1]),1]))
SdFD=sd(as.numeric(Censor[2:length(Censor[,1]),1]))

# loop through to create censor regressor
for(x in 1:nrow(Censor)){
  if(Censor[x,1]>CenThresh){
    Censor[x,1]=0
  } else {
    Censor[x,1]=1}
}

CensorPercent= ((length(Censor[2:length(Censor[,1]),1]) - sum(as.numeric(Censor[2:length(Censor[,1]),1])))/length(Censor[2:length(Censor[,1]),1]))*100
# write censor to 1D file
write.table(Censor,paste(OutDir,"/",FilePrefix,"Censor.1D", sep=""), quote = FALSE, sep = "\t", row.names = FALSE, col.names = FALSE)

MotionSummary=data.frame(MeanFD,MaxFD,SdFD,CensorPercent)
write.table(MotionSummary,paste(OutDir,"/",FilePrefix,"MotionSummary.csv", sep=""), quote = FALSE, sep = ",", row.names = FALSE, col.names = TRUE)