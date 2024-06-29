/**
 * @typedef {Object} Resume
 * @property {Object[]} work
 * @property {string} work.employer
 * @property {Object[]} work.jobs
 * @property {string} work.jobs.title
 * @property {string} work.jobs.date
 * @property {string[]} work.jobs.description
 */

/**
 * @type Resume
 */
const resume = {
  work: [
    {
      employer: "TD Bank",
      jobs: [
        {
          title: "Senior IT Developer",
          date: "November 2022 - Present",
          description: [
            "UREFA and CLUA",
            "Common code library",
            "LDCA",
            "microapp",
          ],
        },
        {
          title: "IT Developer III",
          date: "November 2022 - November 2022",
          description: [],
        },
        {
          title: "IT Consultant",
          date: "November 2019 - November 2021",
          description: [
            "Developed a mortgage underwriting web application for thousands of users written in Angular",
            "Migrated a legacy ETL system to route millions of records per year to separate lines of businesses using the Cinchy platform",
            "Lead performance testing of ETL system to provide infrastructure and code was stable",
            "Created a Kotlin Spring batch application that directly moved data from files to a Salesforce table",
            "Participated in daily scrum and agile practices to focus the team's goals and provide a space to flexibly work around ploblems as they arose",
          ],
        },
      ],
    },
    {
      "employer": "Environment and Climate Change Canada",
      "jobs": [
        {
          "title": "Software Developer",
          "date": "September 2017 - August 2018",
          "description": [
            "Developed a Java component that decoded raw input of weather sensors located in Metro Vancouver into a standard XML format for other products to use, such as the mobile weather app or air traffic control systems",
            "Created an Angular website to manipulate generic metadata within systems, targeting scientists and managers as users",
            "Collaborated with the team to design an anomaly detection system that automatically notified managers and support staff of production issues, so they could return the system to its original state in a timely fashion",
            "Participated with other developers in the validation process of the development life cycle",
            "Documented all design and research on a wiki to clearly communicate to other developers the design and purpose of the products that were created",
          ],
        },
      ],
    },
    {
      "employer": "LBCIT Solutions",
      "jobs": [
        {
          "title": "Junior Web Developer",
          "date": "May 2016 - August 2016",
          "description": [
            "Used WordPress, Microsoft .NET, HTML5, CSS3, PHP, C#, JavaScript, and other technologies to create and maintain websites for multiple companies: Six Words Communication, Second Cup, TELUS, WE Charity, Canadian Association for Co- operative Education, and Canadian Board Diversity Council",
            "Designed wireframes with Balsmiq Mock-ups, used to propose a website design to a client and gain their business",
            "Worked directly with one client to obtain requirements and created a first draft of their website",
          ],
        },
      ],
    },
  ],
};

const workFrag = document.createDocumentFragment();
for (const w of resume.work) {
    const header = document.createElement("h2");
    header.textContent = "Work";


    for (const job of w.jobs) {
        const title = document.createElement("div");
        title.textContent = job.title;
        title.className = "title";
        workFrag.append(title);

        const date = document.createElement("div");
        date.textContent = job.date;
        workFrag.append(date);
    }
}
document.getElementById("work").append(workFrag);

