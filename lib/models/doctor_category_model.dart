class DoctorCategory {
  final String name;
  final String imageUrl; // URL to the icon image for the category

  DoctorCategory({required this.name, required this.imageUrl});

  // You can define a static list of your categories here
  static List<DoctorCategory> get defaultCategories => [
    DoctorCategory(name: "Cardiologist", imageUrl: "https://www.shutterstock.com/image-vector/heart-icon-flat-style-vector-260nw-2471170027.jpg"),
    DoctorCategory(name: "Dermatologist", imageUrl: "https://i.pinimg.com/564x/16/1e/cf/161ecfc9374d695adf7585191a1bd615.jpg"),
    DoctorCategory(name: "Neurologist", imageUrl: "https://static.vecteezy.com/system/resources/previews/033/064/255/non_2x/brain-research-neurologist-color-icon-illustration-vector.jpg"),
    DoctorCategory(name: "Pediatrician", imageUrl: "https://static.vecteezy.com/system/resources/previews/033/347/241/non_2x/pediatrician-icon-in-illustration-vector.jpg"),
    DoctorCategory(name: "Orthopedic", imageUrl: "https://cdn1.vectorstock.com/i/1000x1000/58/15/orthopedic-icon-design-vector-39505815.jpg"),
    DoctorCategory(name: "Ophthalmologist", imageUrl: "https://static.vecteezy.com/system/resources/previews/027/374/000/non_2x/eye-care-icon-ophthalmology-design-isolated-on-white-background-vector.jpg"),
    DoctorCategory(name: "Physician", imageUrl: "https://cdn-icons-png.flaticon.com/512/6660/6660279.png"),
    DoctorCategory(name: "Gynecology", imageUrl: "https://icon-library.com/images/gynecology-icon/gynecology-icon-27.jpg"),
    DoctorCategory(name: "Radiologist", imageUrl: "https://cdn-icons-png.flaticon.com/512/3755/3755847.png"),
  ];
}