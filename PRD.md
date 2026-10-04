# Product Requirements Document (PRD)
## Project: Field Supervisor Attendance & Petty Cash App
## Phase: 1 (Demo Version - Internal Mock State)

### 1. Objective
Develop a mobile application for construction field supervisors to record daily attendance via geotagging/selfies and manage petty cash/reimbursement claims. Phase 1 focuses exclusively on front-end UI/UX and mock backend services for client demonstration.

### 2. Core Features (Phase 1)
#### 2.1. Dashboard (Home)
- Display user information (Name, Role, Active Project Site).
- Display a high-level summary of monthly attendance.
- Two primary Call-to-Action (CTA) buttons: "Clock In/Out" and "Reimbursement".

#### 2.2. Attendance System (Geotag & Selfie)
- **UI Layout:** Split screen layout. Top half for camera preview, bottom half for map/location data.
- **Data Display:** Show mock real-time timestamp, mock Latitude/Longitude, and a mapped address.
- **Action:** A submit button that saves the record into the local mock state.

#### 2.3. History (Calendar View)
- A calendar interface highlighting past attendance.
- Status indicators (e.g., Green dot for present, Red for absent).
- Interactive dates: Tapping a date opens a bottom sheet detailing the exact clock-in time, location, and mock photo for that day.

#### 2.4. Reimbursement Management
- **List View:** A history of submitted claims categorized by status (Pending, Approved).
- **Form:** Input fields for Amount, Category (Material, Transport, Meals), Notes, and a file picker/camera mock for receipt uploads.

### 3. Technical & Architectural Constraints
- **Framework:** Flutter (Dart).
- **Architecture Pattern:** MVVM or Clean Architecture. It is STRICTLY REQUIRED to decouple the UI from the Data Layer. Use Repositories with mock data now, so they can be easily swapped with external API/Database calls in Phase 2.
- **Data Source:** In-memory lists/variables only. No external API calls.
- **Code Standards:** 
  - 100% English nomenclature for variables, functions, and classes.
  - Clean, enterprise-grade code. No redundant AI-generated comments (no "AI slop").
  - Do not implement real device hardware access (Camera/GPS) yet; use mock UI widgets to simulate them for the demo.