withr::local_locale(c("LC_TIME" = "en"))
rmarkdown::render(
  input             = "cv/Fernando da Silva.Rmd", 
  output_dir        = "cv", 
  output_file       = paste0(Sys.Date(), "-Fernando-da-Silva-CV.pdf"),
  intermediates_dir = "CV"
  )
