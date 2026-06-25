import '../models/course.dart';

Course _c({
  required String code,
  required String name,
  required int ch,
  required int year,
  required int sem,
  String stream = 'Common',
  List<String> prerequisites = const [],
}) {
  return Course(
    code: code,
    name: name,
    ch: ch,
    year: year,
    sem: sem,
    stream: stream,
    prerequisites: prerequisites,
  );
}

/// ECE curriculum (Years 2–5) from AASTU Student Handbook 2023/2024 §3.5.
List<Course> getEceCourses() {
  return [
    // --- Year 2, Semester 1 ---
    _c(code: 'Comp2003', name: 'Introduction to Computer Programming', ch: 3, year: 2, sem: 1),
    _c(code: 'GLTr2011', name: 'Global Trend', ch: 2, year: 2, sem: 1),
    _c(code: 'MEng2001', name: 'Engineering Drawing', ch: 3, year: 2, sem: 1),
    _c(code: 'CEng2005', name: 'Engineering Mechanics I (Statics)', ch: 3, year: 2, sem: 1),
    _c(code: 'Math2007', name: 'Applied Mathematics IIB', ch: 4, year: 2, sem: 1, prerequisites: ['Math1014']),
    _c(code: 'Econ2009', name: 'Economics', ch: 3, year: 2, sem: 1),

    // --- Year 2, Semester 2 ---
    _c(code: 'ECEg2102', name: 'Fundamentals of Electrical Engineering', ch: 4, year: 2, sem: 2, prerequisites: ['Phys1001']),
    _c(code: 'MEng2102', name: 'Engineering Mechanics II (Dynamics)', ch: 3, year: 2, sem: 2, prerequisites: ['CEng2005']),
    _c(code: 'Math2042', name: 'Applied Mathematics IIIB', ch: 4, year: 2, sem: 2, prerequisites: ['Math2007']),
    _c(code: 'ECEg2110', name: 'Probability and Random Processes', ch: 3, year: 2, sem: 2, prerequisites: ['Math2007']),
    _c(code: 'MEng2114', name: 'Engineering Thermodynamics', ch: 3, year: 2, sem: 2),
    _c(code: 'Hist2002', name: 'History of Ethiopia and the Horn', ch: 3, year: 2, sem: 2),

    // --- Year 3, Semester 1 ---
    _c(code: 'ECEg3101', name: 'Computational Methods', ch: 3, year: 3, sem: 1, prerequisites: ['Math2042', 'Comp2003']),
    _c(code: 'ECEg3103', name: 'Applied Electronics I', ch: 4, year: 3, sem: 1, prerequisites: ['ECEg2102']),
    _c(code: 'ECEg3105', name: 'Signals and System Analysis', ch: 3, year: 3, sem: 1, prerequisites: ['Math2042']),
    _c(code: 'ECEg3107', name: 'Electromagnetic Fields', ch: 3, year: 3, sem: 1, prerequisites: ['ECEg2102']),
    _c(code: 'ECEg3109', name: 'Object Oriented Programming', ch: 3, year: 3, sem: 1, prerequisites: ['Comp2003']),
    _c(code: 'ECEg3111', name: 'Research Methods and Presentation', ch: 2, year: 3, sem: 1),
    _c(code: 'ECEg3113', name: 'Electrical Workshop Practices I', ch: 1, year: 3, sem: 1),

    // --- Year 3, Semester 2 ---
    _c(code: 'ECEg3102', name: 'Applied Electronics II', ch: 3, year: 3, sem: 2, prerequisites: ['ECEg3103']),
    _c(code: 'ECEg3104', name: 'Digital Logic Design', ch: 4, year: 3, sem: 2, prerequisites: ['ECEg3102']),
    _c(code: 'ECEg3106', name: 'Network Analysis and Synthesis', ch: 3, year: 3, sem: 2, prerequisites: ['ECEg3105']),
    _c(code: 'ECEg3108', name: 'Digital Signal Processing', ch: 4, year: 3, sem: 2, prerequisites: ['ECEg3105']),
    _c(code: 'ECEg3110', name: 'Electrical Machines I', ch: 4, year: 3, sem: 2, prerequisites: ['ECEg3107']),
    _c(code: 'ECEg3112', name: 'Electrical Workshop Practices II', ch: 2, year: 3, sem: 2),

    // --- Year 4, Semester 1 (Common) ---
    _c(code: 'ECEg4101', name: 'Introduction to Communication Systems', ch: 3, year: 4, sem: 1, prerequisites: ['ECEg3102', 'ECEg3105', 'ECEg2110']),
    _c(code: 'ECEg4103', name: 'Computer Architecture and Organization', ch: 3, year: 4, sem: 1, prerequisites: ['ECEg3104']),
    _c(code: 'ECEg4105', name: 'Introduction to Control Systems', ch: 3, year: 4, sem: 1, prerequisites: ['ECEg3101', 'ECEg3103']),
    _c(code: 'ECEg4107', name: 'Electrical Measurement and Instrumentation', ch: 3, year: 4, sem: 1, prerequisites: ['ECEg2102']),
    _c(code: 'ECEg4109', name: 'Power Systems I', ch: 3, year: 4, sem: 1, prerequisites: ['ECEg3110']),
    _c(code: 'IETP4115', name: 'Integrated Engineering Team Project', ch: 3, year: 4, sem: 1),

    // --- Year 4, Semester 2 — Computer ---
    _c(code: 'ECEg4102', name: 'Microprocessors and Interfacing', ch: 4, year: 4, sem: 2, stream: 'Computer', prerequisites: ['ECEg4103']),
    _c(code: 'ECEg4404', name: 'Data Structures and Algorithm', ch: 4, year: 4, sem: 2, stream: 'Computer'),
    _c(code: 'ECEg4410', name: 'Database Systems', ch: 3, year: 4, sem: 2, stream: 'Computer'),
    _c(code: 'ECEg4112', name: 'Integrated Design Project', ch: 3, year: 4, sem: 2, stream: 'Computer'),
    _c(code: 'ECEg4406', name: 'Data Communications and Computer Networks', ch: 4, year: 4, sem: 2, stream: 'Computer'),
    _c(code: 'ECEg4100', name: 'Industry Internship', ch: 6, year: 4, sem: 2, stream: 'Computer'),

    // --- Year 4, Semester 2 — Communication ---
    _c(code: 'ECEg4102', name: 'Microprocessors and Interfacing', ch: 4, year: 4, sem: 2, stream: 'Communication', prerequisites: ['ECEg4103']),
    _c(code: 'ECEg4304', name: 'Digital Communication Systems', ch: 3, year: 4, sem: 2, stream: 'Communication', prerequisites: ['ECEg4101']),
    _c(code: 'ECEg4406', name: 'Data Communications and Computer Networks', ch: 4, year: 4, sem: 2, stream: 'Communication'),
    _c(code: 'ECEg4308', name: 'EM Waves and Guide Structures', ch: 3, year: 4, sem: 2, stream: 'Communication', prerequisites: ['ECEg3107']),
    _c(code: 'ECEg4112', name: 'Integrated Design Project', ch: 3, year: 4, sem: 2, stream: 'Communication'),
    _c(code: 'ECEg4100', name: 'Industry Internship', ch: 6, year: 4, sem: 2, stream: 'Communication'),

    // --- Year 4, Semester 2 — Control ---
    _c(code: 'ECEg4510', name: 'Modern Control Systems', ch: 3, year: 4, sem: 2, stream: 'Control', prerequisites: ['ECEg4105']),
    _c(code: 'ECEg4704', name: 'Electrical Machines II', ch: 4, year: 4, sem: 2, stream: 'Control', prerequisites: ['ECEg3110']),
    _c(code: 'ECEg4506', name: 'Process Control Fundamentals', ch: 3, year: 4, sem: 2, stream: 'Control'),
    _c(code: 'ECEg4112', name: 'Integrated Design Project', ch: 3, year: 4, sem: 2, stream: 'Control'),
    _c(code: 'ECEg4102', name: 'Microprocessors and Interfacing', ch: 4, year: 4, sem: 2, stream: 'Control', prerequisites: ['ECEg4103']),
    _c(code: 'ECEg4100', name: 'Industry Internship', ch: 6, year: 4, sem: 2, stream: 'Control'),

    // --- Year 4, Semester 2 — Electronics ---
    _c(code: 'ECEg4102', name: 'Microprocessors and Interfacing', ch: 4, year: 4, sem: 2, stream: 'Electronics', prerequisites: ['ECEg4103']),
    _c(code: 'ECEg4304', name: 'Digital Communication Systems', ch: 3, year: 4, sem: 2, stream: 'Electronics'),
    _c(code: 'ECEg4308', name: 'EM Waves and Guide Structures', ch: 3, year: 4, sem: 2, stream: 'Electronics', prerequisites: ['ECEg3107']),
    _c(code: 'ECEg4112', name: 'Integrated Design Project', ch: 3, year: 4, sem: 2, stream: 'Electronics'),
    _c(code: 'ECEg5606', name: 'Analog System Design', ch: 3, year: 4, sem: 2, stream: 'Electronics'),
    _c(code: 'ECEg5608', name: 'Power Electronics', ch: 3, year: 4, sem: 2, stream: 'Electronics'),
    _c(code: 'ECEg4100', name: 'Industry Internship', ch: 6, year: 4, sem: 2, stream: 'Electronics'),

    // --- Year 4, Semester 2 — Power ---
    _c(code: 'ECEg4510', name: 'Modern Control Systems', ch: 3, year: 4, sem: 2, stream: 'Power', prerequisites: ['ECEg4105']),
    _c(code: 'ECEg4704', name: 'Electrical Machines II', ch: 4, year: 4, sem: 2, stream: 'Power', prerequisites: ['ECEg3110']),
    _c(code: 'ECEg4102', name: 'Microprocessors and Interfacing', ch: 4, year: 4, sem: 2, stream: 'Power', prerequisites: ['ECEg4103']),
    _c(code: 'ECEg4112', name: 'Integrated Design Project', ch: 3, year: 4, sem: 2, stream: 'Power'),
    _c(code: 'ECEg4708', name: 'Power Systems II', ch: 4, year: 4, sem: 2, stream: 'Power', prerequisites: ['ECEg4109']),
    _c(code: 'ECEg4100', name: 'Industry Internship', ch: 6, year: 4, sem: 2, stream: 'Power'),

    // --- Year 5, Semester 1 — Computer ---
    _c(code: 'ECEg5409', name: 'Software Engineering', ch: 3, year: 5, sem: 1, stream: 'Computer'),
    _c(code: 'ECEg5401', name: 'Operating Systems', ch: 3, year: 5, sem: 1, stream: 'Computer'),
    _c(code: 'ECEg5403', name: 'Embedded Systems', ch: 4, year: 5, sem: 1, stream: 'Computer'),
    _c(code: 'ECEg5405', name: 'VLSI Design', ch: 3, year: 5, sem: 1, stream: 'Computer'),
    _c(code: 'ECEg5407', name: 'Introduction to Machine Learning', ch: 3, year: 5, sem: 1, stream: 'Computer'),
    _c(code: 'ECEg5511', name: 'Robotics and Computer Vision', ch: 3, year: 5, sem: 1, stream: 'Computer'),
    _c(code: 'ECEg5107', name: 'Final Year Project I', ch: 0, year: 5, sem: 1, stream: 'Computer'),

    // --- Year 5, Semester 2 — Computer ---
    _c(code: 'ECEg5402', name: 'New Trends in Computer Engineering', ch: 2, year: 5, sem: 2, stream: 'Computer'),
    _c(code: 'ECEg5412', name: 'Wireless Communications and Mobile Computing', ch: 4, year: 5, sem: 2, stream: 'Computer'),
    _c(code: 'IEng5104', name: 'Industrial Management and Engineering Economy', ch: 3, year: 5, sem: 2, stream: 'Computer', prerequisites: ['Econ2009']),
    _c(code: 'ECEg5108', name: 'Final Year Project II', ch: 6, year: 5, sem: 2, stream: 'Computer'),

    // --- Year 5 — Communication ---
    _c(code: 'ECEg5301', name: 'Microwave Devices and Systems', ch: 3, year: 5, sem: 1, stream: 'Communication'),
    _c(code: 'ECEg5303', name: 'Fiber Optics Communications', ch: 3, year: 5, sem: 1, stream: 'Communication'),
    _c(code: 'ECEg5305', name: 'Antennas and Radio Wave Propagations', ch: 4, year: 5, sem: 1, stream: 'Communication'),
    _c(code: 'ECEg5307', name: 'Wireless and Mobile Communications', ch: 4, year: 5, sem: 1, stream: 'Communication'),
    _c(code: 'ECEg5605', name: 'Microelectronic Devices and Circuits', ch: 3, year: 5, sem: 1, stream: 'Communication'),
    _c(code: 'ECEg5311', name: 'Telecommunication Networks', ch: 3, year: 5, sem: 1, stream: 'Communication'),
    _c(code: 'ECEg5107', name: 'Final Year Project I', ch: 0, year: 5, sem: 1, stream: 'Communication'),
    _c(code: 'ECEg5302', name: 'Switching and Intelligent Networks', ch: 3, year: 5, sem: 2, stream: 'Communication'),
    _c(code: 'ECEg5410', name: 'Advanced Computer Networks', ch: 3, year: 5, sem: 2, stream: 'Communication'),
    _c(code: 'IEng5104', name: 'Industrial Management and Engineering Economy', ch: 3, year: 5, sem: 2, stream: 'Communication', prerequisites: ['Econ2009']),
    _c(code: 'ECEg5108', name: 'Final Year Project II', ch: 6, year: 5, sem: 2, stream: 'Communication'),

    // --- Year 5 — Control ---
    _c(code: 'ECEg5701', name: 'Power Electronics and Electric Drives', ch: 4, year: 5, sem: 1, stream: 'Control'),
    _c(code: 'ECEg5705', name: 'Electrical Installation', ch: 3, year: 5, sem: 1, stream: 'Control'),
    _c(code: 'ECEg5503', name: 'Embedded Systems for Control Engineering', ch: 3, year: 5, sem: 1, stream: 'Control'),
    _c(code: 'ECEg5507', name: 'Digital Control Systems', ch: 3, year: 5, sem: 1, stream: 'Control'),
    _c(code: 'ECEg5511', name: 'Robotics and Computer Vision', ch: 3, year: 5, sem: 1, stream: 'Control'),
    _c(code: 'ECEg5509', name: 'Industrial Automation', ch: 4, year: 5, sem: 1, stream: 'Control'),
    _c(code: 'ECEg5107', name: 'Final Year Project I', ch: 0, year: 5, sem: 1, stream: 'Control'),
    _c(code: 'ECEg5502', name: 'Instrumentation Engineering', ch: 3, year: 5, sem: 2, stream: 'Control'),
    _c(code: 'ECEg5510', name: 'Artificial Intelligence for Control Engineering', ch: 3, year: 5, sem: 2, stream: 'Control'),
    _c(code: 'IEng5104', name: 'Industrial Management and Engineering Economy', ch: 3, year: 5, sem: 2, stream: 'Control', prerequisites: ['Econ2009']),
    _c(code: 'ECEg5108', name: 'Final Year Project II', ch: 6, year: 5, sem: 2, stream: 'Control'),

    // --- Year 5 — Electronics ---
    _c(code: 'ECEg5301', name: 'Microwave Devices and Systems', ch: 3, year: 5, sem: 1, stream: 'Electronics'),
    _c(code: 'ECEg5307', name: 'Wireless and Mobile Communications', ch: 4, year: 5, sem: 1, stream: 'Electronics'),
    _c(code: 'ECEg5609', name: 'Optoelectronics', ch: 3, year: 5, sem: 1, stream: 'Electronics'),
    _c(code: 'ECEg5605', name: 'Microelectronic Devices and Circuits', ch: 3, year: 5, sem: 1, stream: 'Electronics'),
    _c(code: 'ECEg5405', name: 'VLSI Design', ch: 3, year: 5, sem: 1, stream: 'Electronics'),
    _c(code: 'ECEg5107', name: 'Final Year Project I', ch: 0, year: 5, sem: 1, stream: 'Electronics'),
    _c(code: 'ECEg5602', name: 'Digital Systems Design', ch: 3, year: 5, sem: 2, stream: 'Electronics'),
    _c(code: 'ECEg5604', name: 'IC Technology', ch: 3, year: 5, sem: 2, stream: 'Electronics'),
    _c(code: 'IEng5104', name: 'Industrial Management and Engineering Economy', ch: 3, year: 5, sem: 2, stream: 'Electronics', prerequisites: ['Econ2009']),
    _c(code: 'ECEg5108', name: 'Final Year Project II', ch: 6, year: 5, sem: 2, stream: 'Electronics'),

    // --- Year 5 — Power ---
    _c(code: 'ECEg5703', name: 'Energy Conversion and Rural Electrification', ch: 4, year: 5, sem: 1, stream: 'Power'),
    _c(code: 'ECEg5711', name: 'Power System Protection', ch: 3, year: 5, sem: 1, stream: 'Power'),
    _c(code: 'ECEg5701', name: 'Power Electronics and Electric Drives', ch: 4, year: 5, sem: 1, stream: 'Power'),
    _c(code: 'ECEg5705', name: 'Electrical Installation', ch: 3, year: 5, sem: 1, stream: 'Power'),
    _c(code: 'ECEg5709', name: 'Power Systems Automation', ch: 4, year: 5, sem: 1, stream: 'Power'),
    _c(code: 'ECEg5107', name: 'Final Year Project I', ch: 0, year: 5, sem: 1, stream: 'Power'),
    _c(code: 'ECEg5502', name: 'Instrumentation Engineering', ch: 3, year: 5, sem: 2, stream: 'Power'),
    _c(code: 'ECEg5702', name: 'Power Systems Operation and Control', ch: 4, year: 5, sem: 2, stream: 'Power'),
    _c(code: 'IEng5104', name: 'Industrial Management and Engineering Economy', ch: 3, year: 5, sem: 2, stream: 'Power', prerequisites: ['Econ2009']),
    _c(code: 'ECEg5108', name: 'Final Year Project II', ch: 6, year: 5, sem: 2, stream: 'Power'),
  ];
}
