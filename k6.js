import http from 'k6/http';
import { sleep, check } from 'k6';

export const options = {
    stages: [
        { target: 1000, duration: '1m' },   // ramp up to 1000 virtual users over 1 min
        { target: 5000, duration: '10m' },  // ramp up to 5000 virtual users over 10 min
    ],
};

export default function () {
    // each virtual user hits the todos endpoint once per iteration
    const res = http.get('http://your-Balancer-url-here/api/v1/todos');
    check(res, { 'status was 200': (r) => r.status == 200 });
    sleep(1);   // wait 1s before next iteration
}