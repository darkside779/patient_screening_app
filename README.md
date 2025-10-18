# 🏥 Patient Screening App

A comprehensive **Flutter healthcare application** that enables patients to track symptoms, receive AI-powered health insights, and connect with verified doctors for professional medical consultation.

## 🌟 Features

### 👤 **For Patients**
- **Symptom Tracking**: Record and monitor health symptoms with severity ratings
- **AI Health Analysis**: Get intelligent health insights powered by Google Gemini AI
- **Medical History**: View and manage past symptom entries with advanced filtering
- **Doctor Search**: Find and request consultations from verified healthcare professionals
- **Medical Notes**: View professional notes and recommendations from doctors
- **Profile Management**: Comprehensive account settings and data export

### 👨‍⚕️ **For Doctors**
- **Patient Management**: Access and manage patient records with proper permissions
- **Medical Notes**: Create detailed observations, diagnoses, and treatment recommendations
- **Patient Search**: Find and request access to patient medical records
- **Access Control**: Manage patient data access with privacy controls
- **Professional Dashboard**: Streamlined interface for medical practice management

### 🔐 **For Administrators**
- **User Verification**: Verify doctor credentials and manage user accounts
- **System Oversight**: Monitor platform activity and maintain data integrity
- **Role Management**: Control user permissions and access levels

## 🚀 Technology Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase (Firestore, Authentication, Storage)
- **AI Integration**: Google Gemini AI for health analysis
- **State Management**: Provider pattern with proper lifecycle management
- **Navigation**: GoRouter for declarative routing
- **UI/UX**: Modern Material Design with custom gradients and animations

## 🏗️ Architecture

### **Clean Architecture Principles**
- **Screens**: UI layer with stateful widgets
- **Services**: Business logic and API integrations
- **Models**: Data structures and Firestore serialization
- **Router**: Centralized navigation with role-based access control

### **Key Components**
```
lib/
├── screens/           # UI screens for different user roles
├── services/          # Business logic and external integrations
├── models/           # Data models and Firestore mappings
├── router/           # Navigation and route management
└── main.dart         # App entry point and configuration
```

## 🔧 Setup & Installation

### **Prerequisites**
- Flutter SDK (3.0+)
- Firebase project with Firestore enabled
- Google AI Studio API key

### **Installation Steps**

1. **Clone the repository**
   ```bash
   git clone https://github.com/darkside779/patient_screening_app.git
   cd patient_screening_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Configuration**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com)
   - Enable Firestore Database and Authentication
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place configuration files in respective platform folders

4. **AI Integration Setup**
   - Get API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
   - Update the API key in `lib/services/ai_service.dart`

5. **Run the application**
   ```bash
   flutter run
   ```

## 📱 User Roles & Access

### **Patient Account**
- **Email**: `patient@patient.com`
- **Features**: Symptom tracking, AI analysis, doctor search, medical notes viewing

### **Doctor Account**
- **Email**: `doctor@doctor.com`
- **Features**: Patient management, medical notes creation, access requests

### **Admin Account**
- **Email**: `admin@admin.com`
- **Features**: User verification, system oversight, role management

## 🔐 Security & Privacy

- **Role-based Access Control**: Strict permission system for different user types
- **Data Privacy**: Medical notes with private/public visibility controls
- **Secure Authentication**: Firebase Auth with email verification
- **HIPAA Considerations**: Patient data protection and access logging

## 🎨 UI/UX Highlights

- **Modern Design**: Gradient backgrounds and card-based layouts
- **Responsive Interface**: Optimized for various screen sizes
- **Intuitive Navigation**: Role-specific dashboards and clear user flows
- **Professional Medical Theme**: Healthcare-appropriate color schemes and iconography
- **Accessibility**: Screen reader support and proper contrast ratios

## 🔄 Key Workflows

### **Patient Journey**
1. Register/Login → Home Dashboard
2. Record Symptoms → AI Analysis
3. View History → Search Doctors
4. Request Consultation → View Medical Notes

### **Doctor Journey**
1. Register → Admin Verification
2. Search Patients → Request Access
3. View Patient Records → Create Medical Notes
4. Manage Patient List → Professional Dashboard

## 🚀 Recent Updates

- ✅ **Fixed Firestore Composite Index Issues**: Optimized queries for better performance
- ✅ **Enhanced Patient Medical Notes**: Complete viewing system for doctor notes
- ✅ **Improved AI Integration**: Better error handling and fallback systems
- ✅ **Modern UI Redesign**: Consistent design language across all screens
- ✅ **Advanced Filtering**: Search and filter capabilities for medical records

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- 📧 Email: support@patientscreening.app
- 🐛 Issues: [GitHub Issues](https://github.com/darkside779/patient_screening_app/issues)
- 📖 Documentation: [Wiki](https://github.com/darkside779/patient_screening_app/wiki)

## 🙏 Acknowledgments

- **Google Gemini AI** for intelligent health analysis
- **Firebase** for robust backend infrastructure
- **Flutter Team** for the amazing cross-platform framework
- **Healthcare Professionals** for guidance on medical workflows

---

**⚠️ Medical Disclaimer**: This application provides general health information and should not replace professional medical advice, diagnosis, or treatment. Always consult qualified healthcare providers for medical concerns.
