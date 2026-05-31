import React from 'react';

export function FlutterIconRow({
  label,
  value,
  icon,
  valueColor = '#0f172a',
  bgColor = '#1e293b',
}: {
  label: string;
  value: string;
  icon: React.ReactNode;
  valueColor?: string;
  bgColor?: string;
}) {
  return (
    <div style={{ display: 'flex', alignItems: 'center' }}>
      <div style={{
        minWidth: '18pt', width: '18pt', height: '18pt',
        borderRadius: '5pt',
        display: 'flex',
        alignItems: 'center', justifyContent: 'center',
        backgroundColor: bgColor,
        padding: '3pt',
      }}>
        {icon}
      </div>
      <div style={{ marginRight: '5pt' }}>
        <span style={{
          fontSize: '12pt', fontWeight: 400,
          color: '#0f172a',
          fontFamily: '"Cairo", sans-serif',
        }}>
          {label}:{' '}
        </span>
        <span style={{
          fontSize: '13pt', fontWeight: 700,
          color: valueColor,
          fontFamily: '"Cairo", sans-serif',
        }}>
          {value}
        </span>
      </div>
    </div>
  );
}

export function FlutterGridCell({
  label,
  value,
  icon,
  isTopRow = false,
  bg = 'white',
}: {
  label: string;
  value: string;
  icon: React.ReactNode;
  isTopRow?: boolean;
  bg?: string;
}) {
  return (
    <div style={{
      padding: '6pt 8pt',
      display: 'flex', alignItems: 'center',
      gap: '6pt',
      background: bg,
      borderTop: isTopRow ? 'none' : '1pt solid #e2e8f0',
    }}>
      <div style={{
        minWidth: '20pt', width: '20pt', height: '20pt',
        borderRadius: '4pt',
        display: 'flex',
        alignItems: 'center', justifyContent: 'center',
        backgroundColor: '#1e293b',
        padding: '3pt',
      }}>
        {icon}
      </div>
      <div>
        <span style={{
          fontSize: '11pt', fontWeight: 400,
          color: '#0f172a',
          fontFamily: '"Cairo", sans-serif',
        }}>
          {label}:
        </span>
        <span style={{
          fontSize: '12pt', fontWeight: 700,
          color: '#0f172a',
          fontFamily: '"Cairo", sans-serif',
          marginRight: '4pt',
        }}>
          {value || '-'}
        </span>
      </div>
    </div>
  );
}
