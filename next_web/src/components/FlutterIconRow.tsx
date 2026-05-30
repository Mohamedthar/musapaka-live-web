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
        minWidth: '34px', height: '34px',
        borderRadius: '8px',
        display: 'flex',
        alignItems: 'center', justifyContent: 'center',
        backgroundColor: bgColor,
      }}>
        {icon}
      </div>
      <div style={{ marginRight: '8px' }}>
        <span style={{
          fontSize: '14px', fontWeight: 600,
          color: '#0f172a',
          fontFamily: '"Cairo", sans-serif',
        }}>
          {label}:{' '}
        </span>
        <span style={{
          fontSize: '16px', fontWeight: 700,
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
      padding: '6px 10px',
      display: 'flex', alignItems: 'center',
      gap: '6px',
      background: bg,
      borderTop: isTopRow ? 'none' : '1px solid #e2e8f0',
    }}>
      <div style={{
        minWidth: '28px', height: '28px',
        borderRadius: '6px',
        display: 'flex',
        alignItems: 'center', justifyContent: 'center',
        backgroundColor: '#1e293b',
      }}>
        {icon}
      </div>
      <div>
        <span style={{
          fontSize: '11px', fontWeight: 600,
          color: '#0f172a',
          fontFamily: '"Cairo", sans-serif',
        }}>
          {label}:
        </span>
        <span style={{
          fontSize: '12px', fontWeight: 700,
          color: '#0f172a',
          fontFamily: '"Cairo", sans-serif',
          marginRight: '4px',
        }}>
          {value || '-'}
        </span>
      </div>
    </div>
  );
}
