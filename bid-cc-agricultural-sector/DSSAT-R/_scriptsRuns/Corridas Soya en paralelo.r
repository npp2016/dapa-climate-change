
  
  ############### Parallel DSSAT ############################
  ########### Load functions necessary ###############
  # path_functions <- "/home/jeisonmesa/Proyectos/BID/DSSAT-R/"
  # path_project <- "/home/jeisonmesa/Proyectos/BID/bid-cc-agricultural-sector/"
  
  path_functions <- "/mnt/workspace_cluster_3/bid-cc-agricultural-sector/_scripts/DSSAT-R/"
  path_project <- "/mnt/workspace_cluster_3/bid-cc-agricultural-sector/"
  
  # Cargar data frame entradas para DSSAT
  
  
  load(paste0(path_project, "14-ObjectsR/Soil.RData"))
  rm(list=setdiff(ls(), c("Extraer.SoilDSSAT", "values", "Soil_profile", "Cod_Ref_and_Position_Generic", "make_soilfile"
                          , "Soil_Generic", "wise", "in_data", "read_oneSoilFile", "path_functions", "path_project", "Cod_Ref_and_Position")))
  
  
  load(paste0(path_project, "/08-Cells_toRun/matrices_cultivo/Soybean_riego.RDat"))

 
  source(paste0(path_functions, "main_functions.R"))     ## Cargar funciones principales
  source(paste0(path_functions, "make_xfile.R"))         ## Cargar funcion para escribir Xfile DSSAT
  source(paste0(path_functions, "make_wth.R")) 
  source(paste0(path_functions, "dssat_batch.R"))
  source(paste0(path_functions, "DSSAT_run.R"))
  

  day0 <- crop_riego$N.app.0d
  day_aplication0 <- rep(0, length(day0))
  
  
  day21 <- rep(0, length(crop_riego$N.app.0d))
  day_aplication21 <- rep(21, length(day21))
  
  amount <- data.frame(day0, day21)
  day_app <- data.frame(day_aplication0, day_aplication21)
  
## configuracion Archivo experimental secano
  years <- 71:99   ## Camabiar entre linea base 71:99 o futuro 69:97
  data_xfile <- list()
  data_xfile$crop <- "SOY" 
  data_xfile$exp_details <- "*EXP.DETAILS: BID17101RZ SOY LAC"
  data_xfile$name <- "./JBID.SBX" 
  data_xfile$CR <- "SB"  ## Variable importante 
  ## data_xfile$INGENO <- "IB0118"
  ##data_xfile$INGENO <- substr(crop_riego[, "variedad.1"], 1, 6)   ## Correr Cultivar por region
  data_xfile$INGENO <- rep('IB0045', length(crop_riego[, "variedad.1"]))
  data_xfile$CNAME <- "SZNA"
  data_xfile$initation <- crop_riego$mirca.start
  data_xfile$final <- crop_riego$mirca.end
  data_xfile$system <- "irrigation"  ## Irrigation or rainfed, if is irrigation then automatic irrigation
  data_xfile$year <- years[1]
  data_xfile$nitrogen_aplication <- list(amount = amount, day_app = day_app)
  data_xfile$smodel <- "SBGRO045"     ##  Fin Model
  data_xfile$bname <- "DSSBatch.v45"
  data_xfile$PPOP <- 20   ## Investigar mas acerca de este parametro 
  data_xfile$PPOE <- 20   ## Investigar mas acerca de este parametro 
  data_xfile$PLME <- "S"  ## to rice S semilla T transplanting
  data_xfile$PLDS <- "R"  ## Investigar mas acerca de este parametro 
  data_xfile$PLRD <- 0
  data_xfile$PLRS <- 50
  data_xfile$PLDP <- 3
  data_xfile$SYMBI <- 'Y' ## Y =  Yes, N = Not
  
  
 
  ## load(paste0(path_project, "14-ObjectsR/wfd/", "WDF_all_new.Rdat"))
  
	modelos <- c("bcc_csm1_1", "bnu_esm", "cccma_canesm2", "gfld_esm2g", "inm_cm4", "ipsl_cm5a_lr", "miroc_miroc5",
             "mpi_esm_mr", "ncc_noresm1_m")
  
  i <- 10
  gcm <- paste0("/mnt/workspace_cluster_3/bid-cc-agricultural-sector/14-ObjectsR/14-ObjectsR/", modelos[i],"/Futuro/")
  load(paste0(gcm, "Precipitation.RDat"))
  load(paste0(gcm, "Srad.Rdat"))
  load(paste0(gcm, "Temperatura_2.Rdat"))
  
  # Climate Data Set for WFD or global model of climate change
  climate_data <- list()
  climate_data$year <- 71:99       ## Years where they will simulate yields change between 71:99 or 69:94
  climate_data$Srad <- Srad        ## [[year]][pixel, ]   
  climate_data$Tmax <- Tmax     ## [[year]][pixel, ]
  climate_data$Tmin <- Tmin     ## [[year]][pixel, ]
  climate_data$Prec <- Prec       ## [[year]][pixel, ]
  climate_data$lat <- crop_riego[,"y"]        ## You can include a vector of latitude
  climate_data$long <- crop_riego[, "x"]         ## You can include a vector of longitude
  climate_data$wfd <- "wfd"       ## Switch between "wfd" and "model"
  climate_data$id <- crop_riego[, "Coincidencias"]
  
  ## Entradas para las corridas de DSSAT 
  
  input_data <- list()
  input_data$xfile <- data_xfile
  input_data$climate <- climate_data
  # Xfile(input_data$xfile, 158)
  
  ## Carpetas necesarias donde se encuentra DSSAT compilado y un directorio para las corridas
  # dir_dssat <- "/home/jeisonmesa/Proyectos/BID/DSSAT/bin/csm45_1_23_bin_ifort/"
  # dir_base <- "/home/jeisonmesa/Proyectos/BID/bid-cc-agricultural-sector/Scratch"
  
  
  	dir_dssat <- "/home/jmesa/csm45_1_23_bin_ifort/"
	dir_base <- "/home/jmesa/Scratch"
  
  run_dssat(input_data, 1, dir_dssat, dir_base)
  ## librerias para el trabajo en paralelo
  library(foreach)
  library(doMC)
  
    ##  procesadores en su servidor
  registerDoMC(7)
  Run <- foreach(i = 1:dim(crop_riego)[1]) %dopar% {
    
    run_dssat(input_data, i, dir_dssat, dir_base)
    
  }

  tipo <- "Riego_"
  cultivo <- "Soya_"
  cultivar <- "MSMATGROUP_"

# save(Run,file=paste("/mnt/workspace_cluster_3/bid-cc-agricultural-sector/12-Resultados/Arroz/2021-2048/","_",cultivar,"_",tipo,modelos[i],".RDat",sep=""))
#save(Run, file = paste("/home/jeisonmesa/Proyectos/BID/bid-cc-agricultural-sector/","_", cultivo, siembra,tipo,"WFD","IC.RDat",sep=""))
#save(Run, file = paste("/home/jeisonmesa/Proyectos/BID/bid-cc-agricultural-sector/","_", cultivo,tipo,"WFD_","IC.RDat",sep=""))
save(Run, file = paste("/home/jmesa/", "_", cultivo, tipo, cultivar, modelos[i], "_",  ".RDat",sep=""))
save(Run, file = paste("/home/jmesa/","_", cultivo, tipo, cultivar, 'WFD', ".RDat", sep = ""))

  



  ############### Parallel DSSAT ############################
  ########### Load functions necessary ###############
  # path_functions <- "/home/jeisonmesa/Proyectos/BID/DSSAT-R/"
  # path_project <- "/home/jeisonmesa/Proyectos/BID/bid-cc-agricultural-sector/"

  path_functions <- "/mnt/workspace_cluster_3/bid-cc-agricultural-sector/_scripts/DSSAT-R/"
  path_project <- "/mnt/workspace_cluster_3/bid-cc-agricultural-sector/"

  
  # Cargar data frame entradas para DSSAT
  
  
  load(paste0(path_project, "14-ObjectsR/Soil.RData"))
  rm(list=setdiff(ls(), c("Extraer.SoilDSSAT", "values", "Soil_profile", "Cod_Ref_and_Position_Generic", "make_soilfile"
                          , "Soil_Generic", "wise", "in_data", "read_oneSoilFile", "path_functions", "path_project", "Cod_Ref_and_Position")))
  
  
  load(paste0(path_project, "/08-Cells_toRun/matrices_cultivo/Soybean_secano.RDat"))

  
  source(paste0(path_functions, "main_functions.R"))     ## Cargar funciones principales
  source(paste0(path_functions, "make_xfile.R"))         ## Cargar funcion para escribir Xfile DSSAT
  source(paste0(path_functions, "make_wth.R")) 
  source(paste0(path_functions, "dssat_batch.R"))
  source(paste0(path_functions, "DSSAT_run.R"))
  
  day0 <- crop_secano$N.app.0d
  day_aplication0 <- rep(0, length(day0))
  
  
  day21 <- rep(0, length(crop_secano$N.app.0d))
  day_aplication21 <- rep(21, length(day21))
  
  amount <- data.frame(day0, day21)
  day_app <- data.frame(day_aplication0, day_aplication21)
  
  
## configuracion Archivo experimental secano
  years <- 71:99   ## Camabiar entre linea base 71:99 o futuro 69:97
  data_xfile <- list()
  data_xfile$crop <- "SOY" 
  data_xfile$exp_details <- "*EXP.DETAILS: BID17101RZ SOY LAC"
  data_xfile$name <- "./JBID.SBX" 
  data_xfile$CR <- "SB"  ## Variable importante 
  ## data_xfile$INGENO <- "IB0118"
  ## data_xfile$INGENO <- substr(crop_secano[, "variedad.1"], 1, 6)   ## Correr Cultivar por region
  data_xfile$INGENO <- rep('IB0045', length(crop_secano[, "variedad.1"]))
  data_xfile$CNAME <- "SZNA"
  data_xfile$initation <- crop_secano$mirca.start
  data_xfile$final <- crop_secano$mirca.end
  data_xfile$system <- "rainfed"  ## Irrigation or rainfed, if is irrigation then automatic irrigation
  data_xfile$year <- years[1]
  data_xfile$nitrogen_aplication <- list(amount = amount, day_app = day_app)
  data_xfile$smodel <- "SBGRO045"     ##  Fin Model
  data_xfile$bname <- "DSSBatch.v45"
  data_xfile$PPOP <- 20   ## Investigar mas acerca de este parametro  ppop es 20
  data_xfile$PPOE <- 20   ## Investigar mas acerca de este parametro 
  data_xfile$PLME <- "S"  ## to rice S semilla T transplanting
  data_xfile$PLDS <- "R"  ## Investigar mas acerca de este parametro 
  data_xfile$PLRD <- 0
  data_xfile$PLRS <- 50
  data_xfile$PLDP <- 3
  data_xfile$SYMBI <- 'Y' ## Y =  Yes, N = Not
  
  ## load(paste0(path_project, "14-ObjectsR/wfd/", "WDF_all_new.Rdat"))
  
  	modelos <- c("bcc_csm1_1", "bnu_esm", "cccma_canesm2", "gfld_esm2g", "inm_cm4", "ipsl_cm5a_lr", "miroc_miroc5",
             "mpi_esm_mr", "ncc_noresm1_m")
  
  
  i<- 9
  gcm <- paste0("/mnt/workspace_cluster_3/bid-cc-agricultural-sector/14-ObjectsR/14-ObjectsR/", modelos[i],"/Futuro/")
  load(paste0(gcm, "Precipitation.RDat"))
  load(paste0(gcm, "Srad.Rdat"))
  load(paste0(gcm, "Temperatura_2.Rdat"))
  
  # Climate Data Set for WFD or global model of climate change
  climate_data <- list()
  climate_data$year <- 71:99       ## Years where they will simulate yields change between 71:99 or 69:94
  climate_data$Srad <- Srad        ## [[year]][pixel, ]   
  climate_data$Tmax <- Tmax     ## [[year]][pixel, ]
  climate_data$Tmin <- Tmin     ## [[year]][pixel, ]
  climate_data$Prec <- Prec       ## [[year]][pixel, ]
  climate_data$lat <- crop_secano[,"y"]        ## You can include a vector of latitude
  climate_data$long <- crop_secano[, "x"]         ## You can include a vector of longitude
  climate_data$wfd <- "wfd"       ## Switch between "wfd" and "model"
  climate_data$id <- crop_secano[, "Coincidencias"]
  
  ## Entradas para las corridas de DSSAT 
  
  input_data <- list()
  input_data$xfile <- data_xfile
  input_data$climate <- climate_data
  # Xfile(input_data$xfile, 158)
  
  ## Carpetas necesarias donde se encuentra DSSAT compilado y un directorio para las corridas
  # dir_dssat <- "/home/jeisonmesa/Proyectos/BID/DSSAT/bin/csm45_1_23_bin_ifort/"
  # dir_base <- "/home/jeisonmesa/Proyectos/BID/bid-cc-agricultural-sector/Scratch"

	dir_dssat <- "/home/jmesa/csm45_1_23_bin_ifort/"
	dir_base <- "/home/jmesa/Scratch"
  
  run_dssat(input_data, 1040, dir_dssat, dir_base)
  ## librerias para el trabajo en paralelo
  library(foreach)
  library(doMC)
  
    ##  procesadores en su servidor
  registerDoMC(8)
  Run <- foreach(i = 1:dim(crop_secano)[1]) %dopar% {
    
    run_dssat(input_data, i, dir_dssat, dir_base)
    
  }

  tipo <- "Secano_"
  cultivo <- "Soya_"
  cultivar <- "DonMario_"

# save(Run,file=paste("/mnt/workspace_cluster_3/bid-cc-agricultural-sector/12-Resultados/Arroz/2021-2048/","_",cultivar,"_",tipo,modelos[i],".RDat",sep=""))
#save(Run, file = paste("/home/jeisonmesa/Proyectos/BID/bid-cc-agricultural-sector/","_", cultivo, siembra,tipo,"WFD","IC.RDat",sep=""))
#save(Run, file = paste("/home/jeisonmesa/Proyectos/BID/bid-cc-agricultural-sector/","_", cultivo,tipo,"WFD_","IC.RDat",sep=""))
save(Run, file = paste("/home/jmesa/", "_", cultivo, tipo, cultivar, modelos[i], "_",  ".RDat",sep=""))
save(Run, file = paste("/home/jmesa/","_", cultivo, tipo, cultivar, 'WFD', ".RDat", sep = ""))

  

  



