#!/usr/bin/env python3
"""合并冗余标签和分类。

规则：
- 同义标签合并为规范形式（如 node.js → nodejs）
- 同义分类合并为规范形式（如 office365 → office）
- 合并后去重（同一文章不出现重复标签/分类）
"""

import os
import re
import sys

POSTS_DIR = os.path.join(os.path.dirname(__file__), '..', 'source', '_posts')

# 标签合并映射：旧标签 → 新标签
# 策略：语义归并到更粗粒度，使 50 个显示位能覆盖绝大多数文章
TAG_MERGE = {
    # === 同义词/拼写变体（第一轮已处理，保留） ===
    'node.js': 'nodejs',
    'bestpractice': 'best-practices',
    'containers': 'container',
    'credentials': 'credential',
    'azuread': 'azure-ad',
    'data-structures': 'data-structure',
    'secret': 'secret-management',
    'secrets': 'secret-management',
    'supplychain': 'supply-chain',
    'zerotrust': 'zero-trust',
    'regular-expression': 'regex',
    'wac': 'windows-admin-center',
    'office-365': 'office365',
    'k8s': 'kubernetes',
    'variable': 'variables',
    'functions': 'function',
    'objects': 'object',
    'loganalytics': 'log-analysis',
    'log-analytics': 'log-analysis',
    'monitor': 'monitoring',
    'tips': 'tip',
    'tip个': 'tip',
    'QQ': 'qq',
    'multicloud': 'multi-cloud',
    'healthcheck': 'health-check',
    'cost-optimization': 'cost-management',
    'windows-defender': 'defender',
    'software-deployment': 'deployment',
    'filesystemwatcher': 'filesystem',
    'filesystem-abstraction': 'filesystem',
    'powershell-7': 'powershell',
    'powershellget': 'psgallery',
    'powershell-gallery': 'psgallery',
    'containerization': 'container',
    'container-registry': 'container',
    'container-apps': 'container',
    'ci-cd': 'cicd',
    'text-parsing': 'text-processing',
    'azure-devops': 'devops',
    'graph-api': 'azure',
    'security-monitoring': 'security',
    'security-policy': 'security',
    'code-signing': 'security',
    'secure-coding': 'security',
    'securestring': 'security',
    'pscredential': 'credential',
    'configuration': 'config-management',
    'configuration-management': 'config-management',
    'configuration-as-code': 'devops',

    # === 语义归并：DevOps/CI/CD/IaC → devops ===
    'cicd': 'devops',
    'infrastructure-as-code': 'devops',
    'iac': 'devops',
    'terraform': 'devops',
    'ansible': 'devops',
    'gitops': 'devops',
    'github-actions': 'devops',
    'arm-template': 'devops',
    'bicep': 'devops',
    'blue-green': 'devops',
    'release': 'devops',
    'git': 'devops',
    'version-control': 'devops',

    # === 语义归并：容器/编排 → container ===
    'docker': 'container',
    'kubernetes': 'container',
    'helm': 'container',
    'kubectl': 'container',
    'orchestration': 'container',
    'serverless': 'cloud',
    'microservices': 'container',

    # === 语义归并：AI/LLM → ai ===
    'llm': 'ai',
    'openai': 'ai',
    'ollama': 'ai',
    'local-llm': 'ai',
    'machine-learning': 'ai',
    'copilot': 'ai',
    'nlp': 'ai',
    'natural-language-processing': 'ai',
    'computervision': 'ai',
    'rag': 'ai',
    'vector-search': 'ai',
    'prompt-engineering': 'ai',
    'ai-optimization': 'ai',
    'data-science': 'ai',
    'mcp': 'ai',
    'polyglot': 'ai',
    'notebooks': 'ai',
    'jupyter': 'ai',

    # === 语义归并：云平台 → cloud ===
    'aws': 'cloud',
    'aws-tools': 'cloud',
    'multi-cloud': 'cloud',
    'hybrid-cloud': 'cloud',
    'edge-computing': 'cloud',

    # === 语义归并：Azure 子服务 → azure ===
    'azure-ad': 'azure',
    'azure-functions': 'azure',
    'entra-id': 'azure',
    'microsoft-graph': 'azure',
    'cost-management': 'azure',
    'keyvault': 'azure',
    'cosmosdb': 'azure',
    'service-bus': 'azure',
    'frontdoor': 'azure',
    'azure-bastion': 'azure',
    'azure-monitor': 'azure',
    'azure-policy': 'azure',
    'event-grid': 'azure',
    'app-service': 'azure',
    'container-instances': 'azure',
    'private-endpoint': 'azure',
    'managed-identity': 'azure',
    'app-configuration': 'azure',
    'app-registration': 'azure',
    'service-principal': 'azure',
    'blob': 'azure',
    'api-management': 'azure',
    'load-balancer': 'azure',
    'sql-database': 'azure',
    'virtual-desktop': 'azure',
    'avd': 'azure',
    'runbook': 'azure',
    'backup': 'azure',
    'dsc': 'azure',
    'az-module': 'azure',

    # === 语义归并：安全子领域 → security ===
    'zero-trust': 'security',
    'compliance': 'security',
    'audit': 'security',
    'encryption': 'security',
    'cryptography': 'security',
    'hashing': 'security',
    'certificate': 'security',
    'pki': 'security',
    'x509': 'security',
    'tls': 'security',
    'authentication': 'security',
    'oauth2': 'security',
    'antivirus': 'security',
    'malware': 'security',
    'vulnerability': 'security',
    '0day': 'security',
    'defender': 'security',
    'forensics': 'security',
    'incident-response': 'security',
    'threat-detection': 'security',
    'threat-hunting': 'security',
    'red-team': 'security',
    'privilege-escalation': 'security',
    'lateral-movement': 'security',
    'siem': 'security',
    'sentinel': 'security',
    'att&ck': 'security',
    'devsecops': 'security',
    'supply-chain': 'security',
    'endpoint-protection': 'security',
    'jea': 'security',
    'constrained-endpoint': 'security',
    'data-protection': 'security',
    'privacy': 'security',
    'anonymization': 'security',
    'data-masking': 'security',
    'password-rotation': 'security',
    'role-capability': 'security',
    'conditional-access': 'security',
    'device-compliance': 'security',
    'dpapi': 'security',
    'firewall': 'security',
    'windows-firewall': 'security',
    'uac': 'security',
    'execution-policy': 'security',

    # === 语义归并：测试 → testing ===
    'pester': 'testing',
    'unit-test': 'testing',
    'tdd': 'testing',
    'mocking': 'testing',
    'code-quality': 'testing',
    'psscriptanalyzer': 'testing',
    'linting': 'testing',
    'code-analysis': 'testing',
    'validation': 'testing',

    # === 语义归并：网络 → network ===
    'tcp': 'network',
    'udp': 'network',
    'dns': 'network',
    'dns-records': 'network',
    'dhcp': 'network',
    'http': 'network',
    'api': 'network',
    'rest-api': 'network',
    'web-api': 'network',
    'web-request': 'network',
    'port-forwarding': 'network',
    'tunneling': 'network',
    'networking': 'network',
    'network-share': 'network',
    'network-management': 'network',
    'ip': 'network',
    'ip-address': 'network',
    'cdn': 'network',
    'socket': 'network',
    'proxy': 'network',
    'protocol': 'network',
    'webhook': 'network',

    # === 语义归并：数据格式 → data-format ===
    'json': 'data-format',
    'xml': 'data-format',
    'yaml': 'data-format',
    'csv': 'data-format',
    'html': 'data-format',
    'html-parsing': 'data-format',
    'markdown': 'data-format',
    'toml': 'data-format',
    'xpath': 'data-format',
    'schema': 'data-format',

    # === 语义归并：数据库 → database ===
    'sql': 'database',
    'sql-server': 'database',
    'sqlite': 'database',
    'nosql': 'database',
    'mongodb': 'database',
    'mongoose': 'database',
    'dba': 'database',
    'ado-net': 'database',
    'smo': 'database',
    'etl': 'database',

    # === 语义归并：远程管理 → remoting ===
    'ssh': 'remoting',
    'winrm': 'remoting',
    'remote-management': 'remoting',
    'remote-access': 'remoting',
    'remote-desktop': 'remoting',
    'wsl': 'cross-platform',

    # === 语义归并：Windows 管理 → windows ===
    'windows-update': 'windows',
    'windows-terminal': 'windows',
    'windows-admin-center': 'windows',
    'windows-server': 'windows',
    'windows-service': 'windows',
    'windows-installer': 'windows',
    'winget': 'package-management',
    'chocolatey': 'package-management',
    'msi': 'package-management',
    'psgallery': 'package-management',
    'nuget': 'package-management',
    'psresourceget': 'package-management',
    'packaging': 'package-management',
    'modules': 'module',

    # === 语义归并：脚本/语言特性 → scripting ===
    'regex': 'scripting',
    'pipeline': 'scripting',
    'function': 'scripting',
    'module': 'scripting',
    'advanced-function': 'scripting',
    'parameters': 'scripting',
    'scope': 'scripting',
    'types': 'scripting',
    'object': 'scripting',
    'hashtable': 'scripting',
    'data-structure': 'scripting',
    'variables': 'scripting',
    'error-handling': 'scripting',
    'try-catch': 'scripting',
    'event-handling': 'scripting',
    'async': 'scripting',
    'parallel': 'scripting',
    'runspace': 'scripting',
    'jobs': 'scripting',
    'foreach-parallel': 'scripting',
    'concurrency': 'scripting',
    'multithreading': 'scripting',
    'threading': 'scripting',
    'flow-control': 'scripting',
    'switch': 'scripting',
    'enum': 'scripting',
    'class': 'scripting',
    'oop': 'scripting',
    'reflection': 'scripting',
    'dynamic-parameters': 'scripting',
    'shouldprocess': 'scripting',
    'whatif': 'confirm',
    'argument-completer': 'scripting',
    'tab-completion': 'scripting',
    'type-accelerator': 'scripting',
    'extended-type-system': 'scripting',
    'linq': 'scripting',
    'metaprogramming': 'scripting',
    'ast': 'scripting',
    'parser': 'scripting',
    'object-model': 'scripting',
    'dotnet': 'scripting',
    '.net': 'scripting',
    'csharp': 'scripting',
    'c#': 'scripting',
    'interop': 'scripting',
    'pinvoke': 'scripting',
    'win32': 'scripting',
    'native-api': 'scripting',
    'unmanaged-code': 'scripting',
    'dynamic-loading': 'scripting',
    'crescendo': 'scripting',
    'wrapper': 'scripting',
    'psprovider': 'scripting',
    'cmdlet': 'scripting',
    'module-development': 'scripting',
    'psmodule': 'scripting',
    'bitwise': 'scripting',
    'flags': 'scripting',
    'breakpoint': 'scripting',
    'stacktrace': 'scripting',
    'debugging': 'scripting',
    'debugging': 'scripting',

    # === 语义归并：文本处理 → text-processing ===
    'text': 'text-processing',
    'string': 'text-processing',
    'encoding': 'text-processing',
    'conversion': 'text-processing',
    'diff': 'text-processing',
    'comparison': 'text-processing',
    'pattern-matching': 'text-processing',
    'path-handling': 'text-processing',
    'import-export': 'text-processing',
    'data-transformation': 'text-processing',
    'data-parsing': 'text-processing',
    'data-processing': 'text-processing',
    'data-migration': 'data-processing',
    'data-collection': 'data-processing',
    'data-analysis': 'data-processing',
    'data-query': 'data-processing',
    'data-visualization': 'data-processing',
    'data-storage': 'data-processing',
    'data-pipeline': 'data-processing',
    'analytics': 'data-processing',

    # === 语义归并：监控/日志/可观测 → monitoring ===
    'logging': 'monitoring',
    'log-analysis': 'monitoring',
    'observability': 'monitoring',
    'diagnostics': 'monitoring',
    'alerting': 'monitoring',
    'alerts': 'monitoring',
    'event-log': 'monitoring',
    'events': 'monitoring',
    'event-driven': 'monitoring',
    'event-forwarding': 'monitoring',
    'event-grid': 'monitoring',
    'structured-logging': 'monitoring',
    'centralized-logging': 'monitoring',
    'wef': 'monitoring',
    'transcript': 'monitoring',
    'session-recording': 'monitoring',
    'recording': 'monitoring',
    'prometheus': 'monitoring',
    'grafana': 'monitoring',
    'metrics': 'monitoring',
    'opentelemetry': 'monitoring',
    'tracing': 'monitoring',
    'process-analysis': 'monitoring',
    'device-monitoring': 'monitoring',
    'dashboard': 'monitoring',
    'health-check': 'monitoring',
    'device-health': 'monitoring',

    # === 语义归并：Web/浏览器 → web ===
    'web-scraping': 'web',
    'web-server': 'web',
    'browser-automation': 'web',
    'http-server': 'web',
    'playwright': 'web',
    'selenium': 'web',
    'angularjs': 'web',
    'javascript': 'web',
    'nodejs': 'web',
    'css': 'web',
    'front-end': 'web',
    'ui-automation': 'web',
    'ionic': 'web',
    'xampp': 'web',
    'apache': 'web',

    # === 语义归并：系统管理 → system-management ===
    'scheduled-tasks': 'system-management',
    'task-scheduler': 'system-management',
    'scheduling': 'system-management',
    'filesystem': 'system-management',
    'registry': 'system-management',
    'process': 'system-management',
    'service-management': 'system-management',
    'server-management': 'system-management',
    'system-info': 'system-management',
    'system-maintenance': 'system-management',
    'system-administration': 'system-management',
    'system-interaction': 'system-management',
    'disk-cleanup': 'system-management',
    'patching': 'system-management',
    'memory': 'system-management',
    'hardware': 'system-management',
    'environment': 'system-management',
    'env': 'system-management',
    'settings': 'system-management',
    'print-server': 'system-management',
    'printer': 'system-management',
    'file-server': 'system-management',
    'file-sync': 'system-management',
    'robocopy': 'system-management',
    'rsync': 'system-management',
    'smb': 'system-management',
    'ntfs': 'system-management',
    'iis': 'system-management',
    'hyper-v': 'virtualization',
    'vm': 'virtualization',
    'vmware': 'virtualization',
    'virtual-machine': 'virtualization',
    'virtual-network': 'virtualization',
    'vnet': 'virtualization',
    'virtual-environment': 'virtualization',

    # === 语义归并：身份/用户管理 → identity ===
    'active-directory': 'identity',
    'ad': 'identity',
    'acl': 'identity',
    'user-management': 'identity',
    'identity-management': 'identity',
    'group-policy': 'identity',
    'gpo': 'identity',
    'intune': 'identity',
    'mdm': 'identity',
    'device-management': 'identity',
    'credential': 'identity',
    'secret-management': 'identity',
    'vault': 'identity',

    # === 语义归并：Office/文档 → office ===
    'office365': 'office',
    'excel': 'office',
    'importexcel': 'office',
    'epplus': 'office',
    'outlook': 'office',
    'teams': 'office',
    'email': 'office',

    # === 语义归并：开发工具 → tooling ===
    'vscode': 'tooling',
    'visualstudio': 'tooling',
    'extension': 'tooling',
    'ide': 'tooling',
    'editor': 'tooling',
    'vim': 'tooling',
    'gvim': 'tooling',
    'cli': 'tooling',
    'terminal': 'tooling',
    'oh-my-posh': 'tooling',
    'intellisense': 'tooling',
    'prediction': 'tooling',
    'psreadline': 'tooling',
    'dotfiles': 'tooling',
    'scaffolding': 'tooling',
    'plaster': 'tooling',
    'template': 'tooling',
    'toolkit': 'tooling',
    'toolchain': 'tooling',
    'tool': 'tooling',
    'tool-use': 'tooling',
    'pode': 'tooling',
    'gui': 'tooling',
    'ui': 'tooling',
    'charts': 'tooling',
    'charting': 'tooling',
    'visualization': 'tooling',
    'animation': 'tooling',
    'asciiart': 'tooling',
    'cheatsheet': 'tooling',
    'gallery': 'tooling',
    'documentation': 'tooling',
    'auto-generation': 'tooling',
    'code-generation': 'tooling',
    'profiling': 'tooling',
    'benchmark': 'tooling',
    'format-data': 'tooling',
    'progress': 'tooling',
    'write-progress': 'tooling',
    'notification': 'tooling',
    'clipboard': 'tooling',
    'obsidian': 'tooling',
    'notes': 'tooling',
    'watcher': 'tooling',
    'watcher': 'tooling',

    # === 语义归并：运维/报告 → reporting ===
    'report': 'reporting',
    'dashboard': 'reporting',

    # === 语义归并：其他零散标签 ===
    'download': 'script',
    'link': 'script',
    'delicious': 'script',
    'ed2k': 'script',
    'skill': 'script',
    'advanced': 'script',
    'guide': 'best-practices',
    'guideline': 'best-practices',
    'productivity': 'automation',
    'community': 'qq',
    'mvp': 'qq',
    'learning': 'best-practices',
    'lesson': 'best-practices',
    'study': 'best-practices',
    'ebook': 'best-practices',
    'book': 'best-practices',
    'preface': 'best-practices',
    'review': 'best-practices',
    'year-review': 'best-practices',
    'year-end': 'best-practices',
    'quarterly': 'best-practices',
    'new-year': 'best-practices',
    'holiday': 'best-practices',
    'career': 'best-practices',
    'quality': 'best-practices',
    'robustness': 'best-practices',
    'maintainability': 'best-practices',
    'usability': 'best-practices',
    'user-experience': 'best-practices',
    'development': 'best-practices',
    'develop': 'best-practices',
    'dev-environment': 'best-practices',
    'publishing': 'best-practices',
    'dependency': 'best-practices',
    'governance': 'best-practices',
    'policies': 'best-practices',
    'policy': 'best-practices',
    'feature-flags': 'best-practices',
    'new-features': 'best-practices',
    'update': 'best-practices',
    'compatibility': 'best-practices',
    'customization': 'best-practices',
    'style': 'best-practices',
    'planning': 'best-practices',
    'collaboration': 'best-practices',
    'recovery': 'best-practices',
    'disaster-recovery': 'best-practices',
    'high-availability': 'best-practices',
    'resource': 'best-practices',
    'resource-orchestration': 'best-practices',
    'ecoystem': 'best-practices',
    'ecosystem': 'best-practices',
    'block': 'best-practices',
    'workflow': 'automation',
    'batch': 'automation',
    'green-computing': 'best-practices',
    'energy-optimization': 'best-practices',
    'predictive-maintenance': 'best-practices',
    'digital-assets': 'best-practices',
    'summary': 'best-practices',
    'remote': 'remoting',
    'invoke-command': 'remoting',
    'repack': 'tooling',
    'appz': 'tooling',
    'blog': 'best-practices',
    'hexo': 'best-practices',
    'messaging': 'network',
    'message-queue': 'network',
    'msmq': 'network',
    'queue': 'network',
    'mqtt': 'network',
    'ddns': 'network',
    'oray': 'network',
    'name-resolution': 'network',
    'server': 'system-management',
    'endpoint': 'network',
    'billing': 'best-practices',
    'iso': 'best-practices',
    'embedded': 'best-practices',
    'industrial-iot': 'best-practices',
    'iot': 'best-practices',
    'ethereum': 'best-practices',
    'smart-contract': 'best-practices',
    'web3': 'best-practices',
    'metaverse': 'best-practices',
    'infrastructure': 'system-management',
    'deployment': 'devops',
    'management': 'system-management',
    'optimization': 'performance',
}

# 分类合并映射
CAT_MERGE = {
    'office365': 'office',
    'system': 'system-administration',
}


def process_file(filepath):
    """处理单篇文章，返回 (是否修改, 修改详情)。"""
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    m = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not m:
        return False, []

    fm = m.group(1)
    lines = fm.split('\n')
    changes = []
    new_lines = []
    in_tags = False
    in_cats = False
    seen_tags = set()
    seen_cats = set()

    for line in lines:
        stripped = line.strip()

        if stripped.startswith('tags:'):
            in_tags = True
            in_cats = False
            new_lines.append(line)
            continue
        if stripped.startswith('categories:'):
            in_cats = True
            in_tags = False
            new_lines.append(line)
            continue
        if not line.startswith(' ') and not line.startswith('-'):
            in_tags = False
            in_cats = False
            new_lines.append(line)
            continue

        if in_tags:
            item = stripped.lstrip('- ').strip()
            if item:
                new_item = TAG_MERGE.get(item, item)
                if new_item != item:
                    changes.append(f'tag: {item} → {new_item}')
                # 去重
                if new_item in seen_tags:
                    changes.append(f'tag dedup: skip {new_item}')
                    continue
                seen_tags.add(new_item)
                if new_item != item:
                    new_lines.append(f'{line[:len(line)-len(line.lstrip())]}- {new_item}')
                else:
                    new_lines.append(line)
            else:
                new_lines.append(line)
        elif in_cats:
            item = stripped.lstrip('- ').strip()
            if item:
                new_item = CAT_MERGE.get(item, item)
                if new_item != item:
                    changes.append(f'cat: {item} → {new_item}')
                if new_item in seen_cats:
                    changes.append(f'cat dedup: skip {new_item}')
                    continue
                seen_cats.add(new_item)
                if new_item != item:
                    new_lines.append(f'{line[:len(line)-len(line.lstrip())]}- {new_item}')
                else:
                    new_lines.append(line)
            else:
                new_lines.append(line)
        else:
            new_lines.append(line)

    if not changes:
        return False, []

    new_fm = '\n'.join(new_lines)
    new_content = f'---\n{new_fm}\n---{content[m.end():]}'
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)

    return True, changes


def main():
    dry_run = '--dry-run' in sys.argv

    files = sorted(os.listdir(POSTS_DIR))
    modified = 0
    total_changes = []

    for filename in files:
        if not filename.endswith('.md'):
            continue
        filepath = os.path.join(POSTS_DIR, filename)

        if dry_run:
            # 只统计不变更
            m = re.match(r'^---\n(.*?)\n---', open(filepath, encoding='utf-8').read(), re.DOTALL)
            if not m:
                continue
            fm = m.group(1)
            for line in fm.split('\n'):
                stripped = line.strip()
                item = stripped.lstrip('- ').strip()
                if item and item in TAG_MERGE:
                    total_changes.append(f'{filename}: {item} → {TAG_MERGE[item]}')
        else:
            changed, changes = process_file(filepath)
            if changed:
                modified += 1
                for c in changes:
                    print(f'  [{filename}] {c}')

    if dry_run:
        print(f'\n需要修改的标签/分类映射: {len(total_changes)} 处')
        for c in total_changes[:30]:
            print(f'  {c}')
        if len(total_changes) > 30:
            print(f'  ... 还有 {len(total_changes) - 30} 处')
    else:
        print(f'\n修改: {modified} 篇文章')


if __name__ == '__main__':
    main()
