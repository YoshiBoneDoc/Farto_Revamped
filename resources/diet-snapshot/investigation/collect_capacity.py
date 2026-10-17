#!/usr/bin/env python3
"""Keep complete counterfactual schedules, capacities and equipment alongside results."""
from pathlib import Path
import argparse,json
p=argparse.ArgumentParser();p.add_argument('directory',type=Path);p.add_argument('output',type=Path);a=p.parse_args()
result={'production_sha256':(a.directory/'source.sha256').read_text().strip(),'food':[],'results':[],'farming_intervals':{},'complete_schedules':{},'equipment':{},'deltas':{}}
for row in (a.directory/'output.log').read_text().splitlines():
 if row.startswith('AUDIT FOOD '):result['food'].append(row[11:])
 elif row.startswith('AUDIT RESULT '):result['results'].append(row[13:])
 elif row.startswith('AUDIT PROFILE '):result['profile']=row[14:]
 elif row.startswith('AUDIT DELTA '):
  key,value=row[12:].split('=');result['deltas'][key]=float(value)
 elif row.startswith('AUDIT FARM '):
  label,data=row[11:].split(' ',1);result['farming_intervals'].setdefault(label,[]).append(data)
 elif row.startswith('AUDIT ROW '):
  label,index,data=row[10:].split(' ',2);result['complete_schedules'].setdefault(label,[]).append(data)
 elif row.startswith('AUDIT GEAR '):
  label,rest=row[11:].split(' ',1);n,data=rest.split(' ',1);result['equipment'].setdefault(label,{}).setdefault(n,[]).append(data)
assert len(result['results'])==4 and len(result['complete_schedules'])==4
assert 'Runtime result=OK' in (a.directory/'output.log').read_text()
a.output.write_text(json.dumps(result,indent=2)+'\n')
