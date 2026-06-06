const fs = require('fs');
const path = require('path');

const files = [
  'lib/presentation/screens/teacher/analytics/teacher_analytics_screen.dart',
  'lib/presentation/screens/admin/users/admin_user_management_screen.dart',
  'lib/presentation/screens/admin/reports/admin_generate_report_screen.dart',
  'lib/presentation/screens/admin/academic/admin_academic_structure_screen.dart',
  'lib/presentation/screens/admin/academic/admin_grade_levels_screen.dart',
  'lib/presentation/screens/admin/academic/admin_section_details_screen.dart',
  'lib/presentation/screens/admin/dashboard/admin_home_view.dart',
];

const importLine = "import 'package:scimathix/core/utils/app_logger.dart';";

files.forEach(file => {
  const fullPath = path.resolve(file);
  let content = fs.readFileSync(fullPath, 'utf8');
  
  // Add import if not already present
  if (!content.includes("app_logger.dart")) {
    // Add after the last import
    const lastImportIdx = content.lastIndexOf("import '");
    if (lastImportIdx !== -1) {
      const endOfLine = content.indexOf('\n', lastImportIdx);
      content = content.slice(0, endOfLine + 1) + importLine + '\n' + content.slice(endOfLine + 1);
    }
  }
  
  // Replace print('... Error: $e') patterns
  content = content.replace(/print\('([^']+) [Ee]rror: \$e'\)/g, "AppLogger.error('$1', e)");
  
  // Replace print('... error: $e') patterns  
  content = content.replace(/print\('([^']+) error: \$e'\)/g, "AppLogger.error('$1', e)");
  
  fs.writeFileSync(fullPath, content, 'utf8');
  console.log(`Fixed: ${file}`);
});
