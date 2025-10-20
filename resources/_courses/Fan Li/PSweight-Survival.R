CensorScoreWithCox=function(CoxModel,TimeVec) {
  LinearPredictor=CoxModel$linear.predictors
  BaselineHazardForm=basehaz(CoxModel,centered=T) # baseline hazard form
  BaselineHazard=sapply(TimeVec, function(x) { # obtain the baseline hazard for Time Vec
    BaselineHazardForm[which.min(abs(BaselineHazardForm$time-x))[1],"hazard"]
  })
  CensorScore=  exp(-BaselineHazard*exp(LinearPredictor)) # obtain censoring probability
  return(CensorScore)
}

SurvEffectWithCox0=function(Data,
                           t=60,
                           Treatment,
                           SurvTime,
                           Status,
                           PS.formula,
                           Censor.formula,
                           Type=1,
                           Method="IPTW",
                           alpha=0.05,
                           q=0.01,
                           Output="S1") {
  # Censoring score function
  CensorScoreFun=function(CoxModel,TimeVec) {
    LinearPredictor=CoxModel$linear.predictors
    BaselineHazardForm=basehaz(CoxModel,centered=T) # baseline hazard data frame
    BaselineHazard=sapply(TimeVec, function(x) { # obtain the baseline hazard for Time Vec
      BaselineHazardForm[which.min(abs(BaselineHazardForm$time-x))[1],"hazard"]
    })
    CensorScore=  exp(-BaselineHazard*exp(LinearPredictor)) # obtain censoring probability
    return(CensorScore)
  }
  # estimate propensity scores
  PS.model=glm(PS.formula,data=Data,family=binomial(link="logit"))
  PS = 1/(1+exp(-c(PS.model$linear.predictors)))
  # Cox Model for the treatment group
  Data.trt=subset(Data,Data[,Treatment]==1)
  assign("Data.trt", Data.trt, envir = .GlobalEnv)
  Censor.trt.model = survival::coxph(Censor.formula,data=Data.trt) 
  # Cox Model for the control group
  Data.con=subset(Data,Data[,Treatment]==0)
  assign("Data.con", Data.con, envir = .GlobalEnv)
  Censor.con.model = survival::coxph(Censor.formula,data=Data.con) 
  if (Method=="IPTW") {
    w.trt = 1/PS[which(Data[,Treatment]==1)]
    w.con = 1/(1-PS[which(Data[,Treatment]==0)])
    if (Type==1) {
      Kc.trt=CensorScoreFun(CoxModel=Censor.trt.model,TimeVec=Data.trt[,SurvTime])
      Kc.con=CensorScoreFun(CoxModel=Censor.con.model,TimeVec=Data.con[,SurvTime])
      delta1 = sapply(t,function(x) 1-sum(w.trt*Data.trt[,Status]*as.numeric(Data.trt[,SurvTime]<=x)/Kc.trt)/sum(w.trt) )
      delta0 = sapply(t,function(x) 1-sum(w.con*Data.con[,Status]*as.numeric(Data.con[,SurvTime]<=x)/Kc.con)/sum(w.con) )
    } else {
      Kc.trt=CensorScoreFun(CoxModel=Censor.trt.model,TimeVec=rep(t,length(Censor.trt.model$y)))
      Kc.con=CensorScoreFun(CoxModel=Censor.con.model,TimeVec=rep(t,length(Censor.con.model$y)))
      delta1 = sapply(t,function(x) sum(w.trt*as.numeric(Data.trt[,SurvTime]>x)/Kc.trt)/sum(w.trt) )
      delta0 = sapply(t,function(x) sum(w.con*as.numeric(Data.con[,SurvTime]>x)/Kc.con)/sum(w.con) )
    }
  } else if (Method=="OW") {
    w.trt = 1-PS[which(Data[,Treatment]==1)]
    w.con = PS[which(Data[,Treatment]==0)]
    if (Type==1) {
      Kc.trt=CensorScoreFun(CoxModel=Censor.trt.model,TimeVec=Data.trt[,SurvTime])
      Kc.con=CensorScoreFun(CoxModel=Censor.con.model,TimeVec=Data.con[,SurvTime])
      delta1 = sapply(t,function(x) 1-sum(w.trt*Data.trt[,Status]*as.numeric(Data.trt[,SurvTime]<=x)/Kc.trt)/sum(w.trt) )
      delta0 = sapply(t,function(x) 1-sum(w.con*Data.con[,Status]*as.numeric(Data.con[,SurvTime]<=x)/Kc.con)/sum(w.con) )
    } else {
      Kc.trt=CensorScoreFun(CoxModel=Censor.trt.model,TimeVec=rep(t,length(Censor.trt.model$y)))
      Kc.con=CensorScoreFun(CoxModel=Censor.con.model,TimeVec=rep(t,length(Censor.con.model$y)))
      delta1 = sapply(t,function(x) sum(w.trt*as.numeric(Data.trt[,SurvTime]>x)/Kc.trt)/sum(w.trt) )
      delta0 = sapply(t,function(x) sum(w.con*as.numeric(Data.con[,SurvTime]>x)/Kc.con)/sum(w.con) )
    }
  } else if (Method=="Symmetric") {
    keep <- ((PS>= alpha) & (PS <= (1-alpha)))
    Data.trim=Data[keep,]
    ## refit propensity and censoring models
    PS.model=glm(PS.formula,data=Data.trim,family=binomial(link="logit"))
    PS = 1/(1+exp(-c(PS.model$linear.predictors)))
    Data.trim.trt=subset(Data.trim,Data.trim[,Treatment]==1)
    Censor.trt.model = coxph(Censor.formula,data=Data.trim.trt) 
    Data.trim.con=subset(Data.trim,Data.trim[,Treatment]==0)
    Censor.con.model = coxph(Censor.formula,data=Data.trim.con) 
    assign("Data.trim.trt", Data.trim.trt, envir = .GlobalEnv)
    assign("Data.trim.con", Data.trim.con, envir = .GlobalEnv)
    if (Type==1) {
      Kc.trt=CensorScoreFun(CoxModel=Censor.trt.model,TimeVec=Data.trim.trt[,SurvTime])
      Kc.con=CensorScoreFun(CoxModel=Censor.con.model,TimeVec=Data.trim.con[,SurvTime])
      w.trt = 1/PS[which(Data.trim[,Treatment]==1)]
      delta1 = sapply(t,function(x) 1-sum(w.trt*Data.trim.trt[,Status]*as.numeric(Data.trim.trt[,SurvTime]<=x)/Kc.trt)/sum(w.trt) )
      w.con = 1/(1-PS[which(Data.trim[,Treatment]==0)])
      delta0 = sapply(t,function(x) 1-sum(w.con*Data.trim.con[,Status]*as.numeric(Data.trim.con[,SurvTime]<=x)/Kc.con)/sum(w.con) )
    } else {
      Kc.trt=CensorScoreFun(CoxModel=Censor.trt.model,TimeVec=rep(t,length(Censor.trt.model$y)))
      Kc.con=CensorScoreFun(CoxModel=Censor.con.model,TimeVec=rep(t,length(Censor.con.model$y)))
      w.trt = 1/PS[which(Data.trim[,Treatment]==1)]
      delta1 = sapply(t,function(x) sum(w.trt*as.numeric(Data.trim.trt[,SurvTime]>x)/Kc.trt)/sum(w.trt) )
      w.con = 1/(1-PS[which(Data.trim[,Treatment]==0)])
      delta0 = sapply(t,function(x) sum(w.con*as.numeric(Data.trim.con[,SurvTime]>x)/Kc.con)/sum(w.con) )
    }
  } else if (Method=="Asymmetric") {
    PS0 <- PS[Data[,Treatment] == 0]
    PS1 <- PS[Data[,Treatment] == 1]
    LowerPS <- max(min(PS0), min(PS1))
    UpperPS <- min(max(PS0), max(PS1))
    keep <- rep(NA, length(PS))
    alpha0 <- as.numeric(quantile(PS0, 1-q/100))
    alpha1 <- as.numeric(quantile(PS1, q/100))
    keep[Data[,Treatment] == 0] <- ((PS0 >= alpha1) & (PS0 <= alpha0) & (PS0 >= LowerPS) & (PS0 <= UpperPS))
    keep[Data[,Treatment] == 1] <- ((PS1 >= alpha1) & (PS1 <= alpha0) & (PS1 >= LowerPS) & (PS1 <= UpperPS))
    Data.trim=Data[keep,]
    ## refit propensity and censoring models
    PS.model=glm(PS.formula,data=Data.trim,family=binomial(link="logit"))
    PS = 1/(1+exp(-c(PS.model$linear.predictors)))
    Data.trim.trt=subset(Data.trim,Data.trim[,Treatment]==1)
    Censor.trt.model = coxph(Censor.formula,data=Data.trim.trt) 
    Data.trim.con=subset(Data.trim,Data.trim[,Treatment]==0)
    Censor.con.model = coxph(Censor.formula,data=Data.trim.con) 
    assign("Data.trim.trt", Data.trim.trt, envir = .GlobalEnv)
    assign("Data.trim.con", Data.trim.con, envir = .GlobalEnv)
    if (Type==1) {
      Kc.trt=CensorScoreFun(CoxModel=Censor.trt.model,TimeVec=Data.trim.trt[,SurvTime])
      Kc.con=CensorScoreFun(CoxModel=Censor.con.model,TimeVec=Data.trim.con[,SurvTime])
      w.trt = 1/PS[which(Data.trim[,Treatment]==1)]
      delta1 = sapply(t,function(x) 1-sum(w.trt*Data.trim.trt[,Status]*as.numeric(Data.trim.trt[,SurvTime]<=x)/Kc.trt)/sum(w.trt) )
      w.con = 1/(1-PS[which(Data.trim[,Treatment]==0)])
      delta0 = sapply(t,function(x) 1-sum(w.con*Data.trim.con[,Status]*as.numeric(Data.trim.con[,SurvTime]<=x)/Kc.con)/sum(w.con) )
    } else {
      Kc.trt=CensorScoreFun(CoxModel=Censor.trt.model,TimeVec=rep(t,length(Censor.trt.model$y)))
      Kc.con=CensorScoreFun(CoxModel=Censor.con.model,TimeVec=rep(t,length(Censor.con.model$y)))
      w.trt = 1/PS[which(Data.trim[,Treatment]==1)]
      delta1 = sapply(t,function(x) sum(w.trt*as.numeric(Data.trim.trt[,SurvTime]>x)/Kc.trt)/sum(w.trt) )
      w.con = 1/(1-PS[which(Data.trim[,Treatment]==0)])
      delta0 = sapply(t,function(x) sum(w.con*as.numeric(Data.trim.con[,SurvTime]>x)/Kc.con)/sum(w.con) )
    }
  } else if (Method=="Treated") {
    w.trt = rep(1,length(PS[which(Data[,Treatment]==1)]))
    w.con = PS[which(Data[,Treatment]==0)]/(1-PS[which(Data[,Treatment]==0)])
    if (Type==1) {
      Kc.trt=CensorScoreFun(CoxModel=Censor.trt.model,TimeVec=Data.trt[,SurvTime])
      Kc.con=CensorScoreFun(CoxModel=Censor.con.model,TimeVec=Data.con[,SurvTime])
      delta1 = sapply(t,function(x) 1-sum(w.trt*Data.trt[,Status]*as.numeric(Data.trt[,SurvTime]<=x)/Kc.trt)/sum(w.trt) )
      delta0 = sapply(t,function(x) 1-sum(w.con*Data.con[,Status]*as.numeric(Data.con[,SurvTime]<=x)/Kc.con)/sum(w.con) )
    } else {
      Kc.trt=CensorScoreFun(CoxModel=Censor.trt.model,TimeVec=rep(t,length(Censor.trt.model$y)))
      Kc.con=CensorScoreFun(CoxModel=Censor.con.model,TimeVec=rep(t,length(Censor.con.model$y)))
      delta1 = sapply(t,function(x) sum(w.trt*as.numeric(Data.trt[,SurvTime]>x)/Kc.trt)/sum(w.trt) )
      delta0 = sapply(t,function(x) sum(w.con*as.numeric(Data.con[,SurvTime]>x)/Kc.con)/sum(w.con) )
    }
  } else {
    stop("The Method should be one of the following four choices: IPTW, OW, Symmetric, and Asymmetric.")
  }
  if (Output=="S1") {
    delta1[which(delta1>1)]=1;delta1[which(delta1<0)]=0
    return(delta1)
  } else if (Output=="S0") {
    delta0[which(delta0>1)]=1;delta0[which(delta0<0)]=0
    return(delta0)
  } else if (Output=="Delta") {
    delta1[which(delta1>1)]=1;delta1[which(delta1<0)]=0
    delta0[which(delta0>1)]=1;delta0[which(delta0<0)]=0
    return(delta1-delta0)
  } else {
    stop("The Output should be one of the following three choices: S1, S0, Delta.")
  }
}

SurvEffectWithCox=function(Data,t=60,Treatment,SurvTime,Status,PS.formula,Censor.formula,
                   Type=1,Method="IPTW",alpha=0.05,q=0.01,Output="S1",CI=1,R=50) {
  if (CI==0) {
    out=SurvEffectWithCox0(Data=Data,t=t,Treatment=Treatment,
                          SurvTime=SurvTime,Status=Status,
                          PS.formula=PS.formula,Censor.formula=Censor.formula,
                          Type=Type,Method=Method,
                          alpha=alpha,q=q,Output=Output)
    return(out)
  }
  ConstructBootFun=function(d,i) {
    out=SurvEffectWithCox0(Data=d[i,],t=t,Treatment=Treatment,
                          SurvTime=SurvTime,Status=Status,
                          PS.formula=PS.formula,Censor.formula=Censor.formula,
                          Type=Type,Method=Method,
                          alpha=alpha,q=q,Output=Output)
    out
  }
  myboot=boot(Data, ConstructBootFun, R = R, stype = "i")
  out <- as.data.frame(matrix(NA,ncol=4,nrow=length(t)))
  out[,1]=t
  out[,2]=myboot$t0
  rownames(out)=names(myboot$t0)
  for (j in (1:length(t))) {
    out[j,3:4]=quantile(myboot$t[,j],probs=c(0.025,0.975))
  }
  colnames(out) <- c("Time","Estimate","CI.lower","CI.upper")
  out
}