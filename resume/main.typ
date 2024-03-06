#import "template.typ": resume, header, education, experience, projects, hackathons, skills

#let yaml_resume(data) = {
  show: resume
  header(data.basics)
  education(data.education)
  experience(data.work)
  projects(data.projects)
  // hackathons(data.hackathons)
  // ctfs(data.ctfs)
  skills(data.skills)
}

#let resume_data = yaml("resume.yaml")
#yaml_resume(resume_data)


