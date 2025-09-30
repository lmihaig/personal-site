#import "template.typ": resume, header, education, experience, projects, hackathons, skills

#let build_resume(resume_data) = {
  show: resume
  header(resume_data.basics)
  education(resume_data.education)
  experience(resume_data.work)
  projects(resume_data.projects)
  // hackathons(resume_data.hackathons)
  // ctfs(resume_data.ctfs)
  skills(resume_data.skills)
}

// #let resume_data = yaml("resume.yaml")
#let resume_data = toml("resume.toml")
#build_resume(resume_data)

