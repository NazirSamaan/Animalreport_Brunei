class AnimalMalayContent {
  final String commonName;
  final String introduction;
  final String habitat;
  final String conservationStatus;

  const AnimalMalayContent({
    required this.commonName,
    required this.introduction,
    required this.habitat,
    required this.conservationStatus,
  });
}

const Map<String, AnimalMalayContent> _contentByScientificName = {
  'Crocodylus porosus': AnimalMalayContent(
    commonName: 'Buaya muara',
    introduction:
        'Buaya muara ialah reptilia besar yang hidup di kawasan muara, hutan bakau dan sungai. Ia boleh hidup di air masin atau air tawar dan merupakan pemangsa penting dalam ekosistem. Jangan hampiri buaya dan sentiasa berhati-hati di tepi air.',
    habitat: 'Muara, hutan bakau, kawasan pesisir dan sungai',
    conservationStatus: 'Kurang Membimbangkan (LC)',
  ),
  'Tomistoma schlegelii': AnimalMalayContent(
    commonName: 'Buaya jejulong (juga dikenali sebagai buaya julung-julung)',
    introduction:
        'Buaya jejulong ialah sejenis buaya bermuncung panjang dan tirus yang hidup terutamanya di sungai air tawar serta kawasan paya. Ia biasanya lebih sukar dilihat berbanding buaya muara. Lindungi habitatnya dan jangan cuba mendekati atau mengganggunya.',
    habitat: 'Sungai air tawar, paya gambut dan hutan paya',
    conservationStatus: 'Terancam (EN)',
  ),
  'Chelonia mydas': AnimalMalayContent(
    commonName: 'Penyu hijau',
    introduction:
        'Penyu hijau ialah penyu laut yang hidup di perairan tropika. Penyu dewasa kebanyakannya memakan rumpai laut dan alga. Jika terlihat penyu atau sarangnya, jangan sentuh, ganggu atau halang laluannya.',
    habitat: 'Perairan pesisir, padang lamun dan pantai bersarang',
    conservationStatus: 'Terancam (EN)',
  ),
  'Nasalis larvatus': AnimalMalayContent(
    commonName: 'Bangkatan (monyet probosis)',
    introduction:
        'Bangkatan, yang juga dikenali sebagai monyet probosis atau monyet Belanda, ialah primat asli Pulau Borneo. Hidung jantan dewasa sangat menonjol. Ia hidup berkumpulan di hutan berhampiran sungai dan kawasan bakau serta memakan daun dan buah.',
    habitat: 'Hutan tebing sungai, bakau dan hutan paya',
    conservationStatus: 'Terancam (EN)',
  ),
  'Helarctos malayanus': AnimalMalayContent(
    commonName: 'Beruang matahari Borneo',
    introduction:
        'Beruang matahari ialah spesies beruang yang paling kecil. Bulunya biasanya hitam dengan tanda cerah pada dada. Ia menggunakan kuku dan lidahnya yang panjang untuk mencari serangga dan madu, selain memakan buah-buahan.',
    habitat: 'Hutan tanah rendah dan hutan bukit',
    conservationStatus: 'Rentan (VU)',
  ),
  'Sus barbatus': AnimalMalayContent(
    commonName: 'Babi berjanggut Borneo',
    introduction:
        'Babi berjanggut Borneo mudah dikenali melalui bulu kasar di sekitar pipi dan muncungnya. Ia mencari buah, akar dan makanan lain di lantai hutan, dan kadangkala bergerak dalam kumpulan.',
    habitat: 'Hutan tropika dan pinggir hutan',
    conservationStatus: 'Hampir Terancam (NT)',
  ),
  'Buceros rhinoceros': AnimalMalayContent(
    commonName: 'Enggang badak (kenyalang)',
    introduction:
        'Enggang badak ialah burung hutan yang besar dengan paruh kuat dan balung menonjol di atasnya. Ia memakan buah-buahan dan membantu menyebarkan biji benih, sekali gus menyokong pertumbuhan hutan.',
    habitat: 'Hutan dipterokarpa tanah rendah dan hutan bukit',
    conservationStatus: 'Rentan (VU)',
  ),
};

AnimalMalayContent? animalMalayContent(Map<String, dynamic> animal) {
  final scientificName = animal['scientific_name']?.toString().trim();
  if (scientificName == null || scientificName.isEmpty) return null;
  return _contentByScientificName[scientificName];
}
