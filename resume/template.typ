#import "@preview/fontawesome:0.1.0": *

// #let accent = rgb("#0000ff")
#FA_SET.update("Brands")

#let resume(body) = {
  set list(indent: 0.3em)
  show list: set text(size: 0.9em)
  show link: underline
  show link: set underline(offset: 2pt)

  set page(
    paper: "a4",
    margin: (x: 1.2cm, y: 1.2cm)
  )

  set text(
    size: 11.5pt,
      font: "Liberation Sans",
  )
  body
}


#let strpdate(isodate) = {
    let date = ""
    if lower(isodate) != "present" {
        date = datetime(
            year: int(isodate.slice(0, 4)),
            month: int(isodate.slice(5, 7)),
            day: int(isodate.slice(8, 10))
        )
        date = date.display("[month repr:short]") + " " + date.display("[year repr:full]")
    } else if lower(isodate) == "present" {
        date = "Present"
    }
    return date
}

#let bold_upper(str) = {
  [*#upper(str)*]
}


#let name_header(name) = {
  set text(size: 2.25em)
  bold_upper(name)
}

#let make_section(title, array, func, show_line: true)={
  let container = []
  
  for item in array{
    container += func(item)
  }

  grid(
    columns: (1fr, 4fr),
    rows: (auto, auto),
    column-gutter: auto,
    bold_upper(title),
    block[#v(2pt)#container],
  )

  if show_line {
    v(5pt)
    line(length: 100%)
  }
}


#let header(d) = {
  align(center,
    block[
      #name_header(d.name) \
      #fa-phone() #d.phone |
      #fa-envelope() #link("mailto:" + d.email)[#d.email] |
      #fa-globe() #link(d.url)[#d.url.split("//").at(-1)] |
      #fa-linkedin() #link(d.linkedin.url)[#d.linkedin.username] |
      #fa-github() #link(d.github.url)[#d.github.username] 
    ]
  )
}

#let education(d) = {

  make_section("Education", d,
  item => {
    let start = strpdate(item.startDate)
    let end = strpdate(item.endDate)
    block[
      *#item.institution* #h(1fr) Bucharest, Romania \
      #item.studyType #item.area #h(1fr) #start #sym.dash.en #end \
    ]
  }
  )
  
}

#let experience(d) = {

  make_section("Work Experience", d, item => {
    let start = strpdate(item.startDate)
    let end = strpdate(item.endDate)
    
    block[
      #link(item.website)[*#item.name*] | #item.position #h(1fr) #item.location \ 
      #item.description #h(1fr) #start #sym.dash.en #end \
      #for bullet in item.highlights {
        [- #bullet]
      }
    ]
  }
  )
}

#let projects(d) = {
  make_section("Projects", d, item=>{
    block[
      #link(item.url)[*#item.name*] | #item.description
      #for desc in item.highlights{
      [ - #desc]
      }
    ]
  })

}

#let hackathons(d) = {
  make_section("Hackathons", d, item=>{
    block[
      *#item.name* | #item.result \ 
      - #item.summary
    ]
  })
}


#let skills(d) = {
  make_section("Skills", d, item=> {
    block[
      *#item.name*: #item.keywords.join(", ")
    ]
  }, show_line: false)

}