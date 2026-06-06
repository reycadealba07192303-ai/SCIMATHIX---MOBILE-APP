const fs = require('fs');
const path = 'c:\\Users\\reyca\\Downloads\\SCIMATHIX\\frontend\\lib\\data\\services\\api_service.dart';

let content = fs.readFileSync(path, 'utf8');

// Add import at the top if not already present
if (!content.includes("import 'package:scimathix/core/utils/app_logger.dart'")) {
  content = "import 'package:scimathix/core/utils/app_logger.dart';\n" + content;
}

// Replace: print('Xxx Error: $e'); -> AppLogger.error('Xxx', e);
content = content.replace(/print\('([^']+) Error: \$e'\)/g, "AppLogger.error('$1', e)");

// Replace: print('Xxx Failed [${...}]: ${...}'); -> AppLogger.warning(...)
content = content.replace(/print\('([^']+)'\)/g, (match, msg) => {
  if (msg.includes('Failed')) {
    return `AppLogger.warning('${msg}')`;
  }
  return match;
});

fs.writeFileSync(path, content, 'utf8');
console.log('Done. Remaining prints:');
const lines = content.split('\n');
lines.forEach((line, i) => {
  if (line.trim().startsWith('print(')) {
    console.log(`  Line ${i+1}: ${line.trim()}`);
  }
});
