#!/usr/bin/env bash
# Быстрая проверка присланного ДЗ за 5-10 минут (плюс чтение plan-файлов).
# Использование: ./quick-check.sh <каталог-с-git-репозиторием | архив.zip>
# Работает на КОПИИ (коммит HEAD или содержимое архива): проверяется то, что студент реально закоммитил/прислал.
# Нужны: terraform, git; желательно gitleaks.
set -u

src="${1:?usage: quick-check.sh <repo-dir|archive.zip>}"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

if [[ "$src" == *.zip ]]; then
  unzip -q "$src" -d "$work"
  list_files() { (cd "$work" && find . -type f -not -path './.git/*' | sed 's|^\./||'); }
else
  git -C "$src" archive HEAD | tar -x -C "$work"
  list_files() { git -C "$src" ls-files; }
fi

# Если архив распаковался в единственный вложенный каталог, заходим в него.
cd "$work"
if [[ $(ls -A | wc -l) -eq 1 && -d "$(ls -A | head -1)" ]]; then cd "$(ls -A | head -1)"; fi

hdr() { printf '\n== %s ==\n' "$1"; }

hdr "1. Запрещённые файлы (должно быть пусто)"
list_files | grep -E 'tfvars$|tfstate|\.pem$|id_rsa$|id_ed25519$|sa-key|backend-s3\.hcl$' || echo "ok"

hdr "2. Секреты"
if command -v gitleaks >/dev/null 2>&1; then
  gitleaks detect --no-git --source . --no-banner || echo "!! gitleaks нашёл утечки"
else
  echo "gitleaks не установлен; эвристический поиск (IAM t1., OAuth y0_, AQAAAA, API-ключи AQVN, статические ключи YC):"
  grep -rEn 't1\.[A-Za-z0-9._-]{20,}|y0_[A-Za-z0-9_-]{20,}|AQAAAA[A-Za-z0-9_-]{10,}|AQVN[A-Za-z0-9_-]{10,}|YC[AM][A-Za-z0-9_-]{20,}' . || echo "ok"
fi

hdr "3. Lock-файл (ожидаем по одному на окружение) и .gitignore"
list_files | grep -E '\.terraform\.lock\.hcl$' || echo "!! lock-файлов нет"
grep -vE '^\s*#' .gitignore 2>/dev/null | grep -n 'terraform.lock' && echo "!! lock-файл в .gitignore"

hdr "4. required_version и версии провайдера"
grep -rEn 'required_version|version *= *"' --include='*.tf' . || echo "!! не найдено"

hdr "5. Устаревший синтаксис network_interface.0"
grep -rEn 'network_interface\.[0-9]' --include='*.tf' . || echo "ok"

hdr "6. Хардкод в модулях (зона, ключ, CIDR)"
grep -rEn 'ru-central1-[abd]|~/\.ssh|[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/[0-9]+' --include='*.tf' modules/ 2>/dev/null | grep -v 'validation\|error_message\|description\|default\|0\.0\.0\.0/0' || echo "ok"

hdr "7. Блок provider и токен в модулях/переменных"
grep -rEn 'provider "yandex"' --include='*.tf' modules/ 2>/dev/null && echo "!! provider внутри модуля"
grep -rEn 'variable "yc_token"|token *=' --include='*.tf' . && echo "!! токен в коде" || echo "ok"

hdr "8. dynamic и копипаста ingress"
grep -rn 'dynamic "ingress"' --include='*.tf' modules/ || echo "!! dynamic ingress не найден"
printf 'литеральных ingress-блоков в модулях: '
grep -rEc '^\s*ingress \{' --include='*.tf' modules/ 2>/dev/null | awk -F: '{s+=$2} END {print s+0}'

hdr "9. validation (нужна хотя бы одна)"
grep -rn 'validation {' --include='*.tf' . | wc -l

hdr "10. Форматирование"
if command -v terraform >/dev/null 2>&1; then
  terraform fmt -check -recursive || echo "!! terraform fmt -check нашёл расхождения"
else
  echo "!! terraform не установлен: fmt/init/validate пропущены"
fi

hdr "11. init + validate по окружениям"
for env in environments/*/; do
  [ -d "$env" ] || continue
  echo "--- $env"
  (cd "$env" && terraform init -backend=false -input=false -no-color >/dev/null 2>&1 \
    && terraform validate -no-color) || echo "!! init/validate упал в $env"
done

hdr "12. Дублирование dev/prod (смотрим глазами)"
if [ -f environments/dev/main.tf ] && [ -f environments/prod/main.tf ]; then
  diff -u environments/dev/main.tf environments/prod/main.tf | head -60
fi

hdr "13. plan-файлы приложены?"
list_files | grep -Ei 'plan.*(dev|prod)|(dev|prod).*plan' || echo "!! вывод plan не найден"

printf '\nГотово. Дальше: прочитайте plan-dev.txt/plan-prod.txt (см. instructor/review-checklist.md, раздел «Как читать plan»).\n'
